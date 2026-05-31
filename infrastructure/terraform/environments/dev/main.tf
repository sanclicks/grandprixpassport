################################################################################
# GrandPrixPassport — Root Terraform Configuration
# Single AWS Account, Multiple VPCs (dev/staging/prod)
# Owner: Sandeep Baroth
################################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state in S3 — one bucket, separate keys per environment
  backend "s3" {
    bucket         = "gpp-terraform-state-${var.account_id}"
    key            = "${var.environment}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "gpp-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "GrandPrixPassport"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Sandeep Baroth"
      CostCenter  = "gpp-${var.environment}"
    }
  }
}

################################################################################
# Call all modules
################################################################################

module "vpc" {
  source      = "../../modules/vpc"
  environment = var.environment
  cidr_block  = var.vpc_cidr
  project     = var.project
}

module "security" {
  source      = "../../modules/security"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  project     = var.project
}

module "auth" {
  source      = "../../modules/auth"
  environment = var.environment
  project     = var.project
}

module "storage" {
  source      = "../../modules/storage"
  environment = var.environment
  project     = var.project
}

module "database" {
  source             = "../../modules/database"
  environment        = var.environment
  project            = var.project
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security.database_sg_id
}

module "lambda" {
  source             = "../../modules/lambda"
  environment        = var.environment
  project            = var.project
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security.lambda_sg_id
  dynamodb_table_arn = module.database.dynamodb_table_arn
  s3_bucket_arn      = module.storage.assets_bucket_arn
}

module "api_gateway" {
  source      = "../../modules/api-gateway"
  environment = var.environment
  project     = var.project
  lambda_arns = module.lambda.function_arns
}

module "cdn" {
  source          = "../../modules/cdn"
  environment     = var.environment
  project         = var.project
  s3_bucket_id    = module.storage.frontend_bucket_id
  api_gateway_url = module.api_gateway.api_url
}

module "monitoring" {
  source          = "../../modules/monitoring"
  environment     = var.environment
  project         = var.project
  lambda_arns     = module.lambda.function_arns
  api_gateway_id  = module.api_gateway.api_id
  alert_email     = var.alert_email
}
