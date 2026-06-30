terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Uses the current user's default AWS credentials.
# Configure via `aws configure` (~/.aws/credentials) or environment variables.
# No access keys are hardcoded — best practice.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Resolves the current authenticated user/role and account.
data "aws_caller_identity" "current" {}

# Fetches the list of Availability Zones in the selected region (Mumbai).
data "aws_availability_zones" "available" {
  state = "available"
}
