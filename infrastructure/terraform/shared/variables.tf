################################################################################
# GrandPrixPassport — Shared Variables
################################################################################

variable "environment" {
  description = "Environment name: dev, staging, prod"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "grandprixpassport"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block — unique per environment"
  type        = string
  # dev:     10.0.0.0/16
  # staging: 10.1.0.0/16
  # prod:    10.2.0.0/16
}

variable "alert_email" {
  description = "Email for CloudWatch alarms and budget alerts"
  type        = string
  default     = "sandeep@grandprixpassport.com"
}

variable "domain_name" {
  description = "Domain name for this environment"
  type        = string
  # dev:     dev.grandprixpassport.com
  # staging: staging.grandprixpassport.com
  # prod:    grandprixpassport.com
}

# Environment-specific sizing
variable "lambda_memory" {
  description = "Lambda memory in MB"
  type        = number
  # dev: 256, staging: 512, prod: 1024
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  # dev: 10, staging: 20, prod: 30
}

variable "enable_waf" {
  description = "Enable WAF (skip in dev to save cost)"
  type        = bool
  # dev: false, staging: true, prod: true
}

variable "enable_shield" {
  description = "Enable AWS Shield Advanced"
  type        = bool
  default     = false
  # Only true in prod if budget allows
}

variable "rds_instance_class" {
  description = "Aurora Serverless v2 min/max ACUs"
  type = object({
    min_capacity = number
    max_capacity = number
  })
  # dev:     { min: 0.5, max: 1 }
  # staging: { min: 0.5, max: 2 }
  # prod:    { min: 1,   max: 8 }
}
