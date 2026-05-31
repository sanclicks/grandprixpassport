################################################################################
# GrandPrixPassport — Security Groups Module
# Environment-isolated — each VPC has its own security groups
# NO cross-environment rules
################################################################################

variable "environment" {}
variable "vpc_id"      {}
variable "project"     {}

locals {
  name_prefix = "${var.project}-${var.environment}"
}

################################################################################
# Lambda Security Group
# Outbound: HTTPS to internet (Claude API, ticket APIs) via NAT
# Inbound: None (Lambda invoked by API Gateway, not by network)
################################################################################
resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Security group for Lambda functions — ${var.environment}"
  vpc_id      = var.vpc_id

  # No inbound rules — Lambda triggered by API Gateway events, not network

  egress {
    description = "HTTPS outbound — Claude API, ticket APIs, Secrets Manager"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "MySQL/Aurora"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.${var.environment == "dev" ? "0" : var.environment == "staging" ? "1" : "2"}.5.0/24",
                   "10.${var.environment == "dev" ? "0" : var.environment == "staging" ? "1" : "2"}.6.0/24"]
  }

  egress {
    description = "Redis/ElastiCache"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    self        = true
  }

  tags = {
    Name        = "${local.name_prefix}-lambda-sg"
    Environment = var.environment
  }
}

################################################################################
# RDS / Aurora Security Group
# Inbound: ONLY from Lambda SG — nothing else
# No public access ever
################################################################################
resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-database-sg"
  description = "Security group for RDS Aurora — ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from Lambda only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  # No egress — DB should not initiate connections

  tags = {
    Name        = "${local.name_prefix}-database-sg"
    Environment = var.environment
  }
}

################################################################################
# ElastiCache (Redis) Security Group
################################################################################
resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-redis-sg"
  description = "Security group for ElastiCache Redis — ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from Lambda only"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  tags = {
    Name        = "${local.name_prefix}-redis-sg"
    Environment = var.environment
  }
}

################################################################################
# WAF (staging + prod only)
################################################################################
resource "aws_wafv2_web_acl" "main" {
  count = var.environment != "dev" ? 1 : 0

  name  = "${local.name_prefix}-waf"
  scope = "CLOUDFRONT"

  default_action { allow {} }

  # AWS Managed Rules — OWASP Top 10
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action { none {} }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate Limiting — 1000 requests per 5 minutes per IP
  rule {
    name     = "RateLimitRule"
    priority = 2
    action { block {} }
    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  # Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3
    override_action { none {} }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = { Environment = var.environment }
}

################################################################################
# Outputs
################################################################################
output "lambda_sg_id"   { value = aws_security_group.lambda.id }
output "database_sg_id" { value = aws_security_group.database.id }
output "redis_sg_id"    { value = aws_security_group.redis.id }
output "waf_arn"        { value = var.environment != "dev" ? aws_wafv2_web_acl.main[0].arn : "" }
