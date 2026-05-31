################################################################################
# GrandPrixPassport — VPC Module
# One VPC per environment in the SAME AWS account
# dev: 10.0.0.0/16 | staging: 10.1.0.0/16 | prod: 10.2.0.0/16
# NO VPC Peering between environments (isolation by design)
################################################################################

variable "environment" {}
variable "cidr_block"  {}
variable "project"     {}

locals {
  name_prefix = "${var.project}-${var.environment}"

  # Subnet CIDRs derived from VPC CIDR
  # Example for prod (10.2.0.0/16):
  # Public:  10.2.1.0/24 (AZ-a), 10.2.2.0/24 (AZ-b)
  # Private: 10.2.3.0/24 (AZ-a), 10.2.4.0/24 (AZ-b)
  # DB:      10.2.5.0/24 (AZ-a), 10.2.6.0/24 (AZ-b)
  vpc_second_octet = split(".", var.cidr_block)[1]
}

################################################################################
# VPC
################################################################################
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${local.name_prefix}-vpc"
    Environment = var.environment
  }
}

################################################################################
# Internet Gateway (public subnets only)
################################################################################
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name_prefix}-igw" }
}

################################################################################
# Public Subnets (ALB, NAT Gateway)
################################################################################
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false  # Never auto-assign public IPs

  tags = {
    Name = "${local.name_prefix}-public-${count.index + 1}"
    Tier = "public"
  }
}

################################################################################
# Private Subnets (Lambda, ECS — no internet ingress)
################################################################################
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + 3)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${local.name_prefix}-private-${count.index + 1}"
    Tier = "private"
  }
}

################################################################################
# Database Subnets (RDS Aurora — most isolated)
################################################################################
resource "aws_subnet" "database" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + 5)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${local.name_prefix}-db-${count.index + 1}"
    Tier = "database"
  }
}

################################################################################
# NAT Gateway (private subnets → internet, e.g. Claude API calls)
# Single NAT in dev to save cost — HA pair in prod
################################################################################
resource "aws_eip" "nat" {
  count  = var.environment == "prod" ? 2 : 1
  domain = "vpc"
  tags   = { Name = "${local.name_prefix}-nat-eip-${count.index + 1}" }
}

resource "aws_nat_gateway" "main" {
  count         = var.environment == "prod" ? 2 : 1
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = { Name = "${local.name_prefix}-nat-${count.index + 1}" }
  depends_on    = [aws_internet_gateway.main]
}

################################################################################
# Route Tables
################################################################################

# Public route table → Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${local.name_prefix}-rt-public" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private route table → NAT Gateway
resource "aws_route_table" "private" {
  count  = var.environment == "prod" ? 2 : 1
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  tags = { Name = "${local.name_prefix}-rt-private-${count.index + 1}" }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[
    var.environment == "prod" ? count.index : 0
  ].id
}

# Database subnets — NO route to internet
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name_prefix}-rt-database" }
  # No routes — completely isolated, accessed only via Lambda in private subnet
}

resource "aws_route_table_association" "database" {
  count          = 2
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

################################################################################
# VPC Endpoints (avoid NAT costs for AWS services)
# Lambda → S3, DynamoDB via VPC endpoint = free + faster
################################################################################
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(
    [for rt in aws_route_table.private : rt.id],
    [aws_route_table.database.id]
  )
  tags = { Name = "${local.name_prefix}-vpce-s3" }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for rt in aws_route_table.private : rt.id]
  tags = { Name = "${local.name_prefix}-vpce-dynamodb" }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags = { Name = "${local.name_prefix}-vpce-secrets" }
}

resource "aws_security_group" "vpce" {
  name        = "${local.name_prefix}-vpce-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }
}

################################################################################
# Flow Logs (security auditing)
################################################################################
resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/gpp/${var.environment}/vpc/flow-logs"
  retention_in_days = var.environment == "prod" ? 90 : 30
}

resource "aws_iam_role" "flow_logs" {
  name = "${local.name_prefix}-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

################################################################################
# Data Sources
################################################################################
data "aws_availability_zones" "available" {
  state = "available"
}

################################################################################
# Outputs
################################################################################
output "vpc_id"              { value = aws_vpc.main.id }
output "public_subnet_ids"   { value = aws_subnet.public[*].id }
output "private_subnet_ids"  { value = aws_subnet.private[*].id }
output "database_subnet_ids" { value = aws_subnet.database[*].id }
output "vpc_cidr"            { value = aws_vpc.main.cidr_block }
