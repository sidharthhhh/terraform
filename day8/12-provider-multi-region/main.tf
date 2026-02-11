terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default provider (us-east-1)
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "MultiRegion Demo"
    }
  }
}

# Additional provider for us-west-2
provider "aws" {
  alias  = "west"
  region = "us-west-2"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "MultiRegion Demo"
      Region    = "us-west-2"
    }
  }
}

# Additional provider for eu-west-1
provider "aws" {
  alias  = "europe"
  region = "eu-west-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "MultiRegion Demo"
      Region    = "eu-west-1"
    }
  }
}

# Additional provider for ap-south-1 (Mumbai - your region!)
provider "aws" {
  alias  = "mumbai"
  region = "ap-south-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "MultiRegion Demo"
      Region    = "ap-south-1"
    }
  }
}

# ============================================================================
# Example 1: Multi-Region S3 Buckets for DR/Backup
# ============================================================================

# Primary bucket in us-east-1 (default provider)
resource "aws_s3_bucket" "primary" {
  bucket = "primary-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "Primary Data Bucket"
    Region  = "us-east-1"
    Purpose = "Primary Storage"
  }
}

# DR bucket in us-west-2 (west provider)
resource "aws_s3_bucket" "dr_west" {
  provider = aws.west
  bucket   = "dr-west-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "DR West Data Bucket"
    Region  = "us-west-2"
    Purpose = "Disaster Recovery"
  }
}

# DR bucket in Europe
resource "aws_s3_bucket" "dr_europe" {
  provider = aws.europe
  bucket   = "dr-europe-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "DR Europe Data Bucket"
    Region  = "eu-west-1"
    Purpose = "Disaster Recovery"
  }
}

# ============================================================================
# Example 2: Multi-Region VPCs for Global Application
# ============================================================================

# VPC in us-east-1
resource "aws_vpc" "us_east" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name   = "US East VPC"
    Region = "us-east-1"
  }
}

# VPC in us-west-2
resource "aws_vpc" "us_west" {
  provider             = aws.west
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name   = "US West VPC"
    Region = "us-west-2"
  }
}

# VPC in Mumbai (your region!)
resource "aws_vpc" "mumbai" {
  provider             = aws.mumbai
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name   = "Mumbai VPC"
    Region = "ap-south-1"
  }
}

# ============================================================================
# Example 3: Multi-Region DynamoDB Tables for Global Low Latency
# ============================================================================

# DynamoDB in us-east-1
resource "aws_dynamodb_table" "users_us_east" {
  name         = "users-us-east"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = {
    Name   = "Users Table US East"
    Region = "us-east-1"
  }
}

# DynamoDB in Mumbai
resource "aws_dynamodb_table" "users_mumbai" {
  provider     = aws.mumbai
  name         = "users-mumbai"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = {
    Name   = "Users Table Mumbai"
    Region = "ap-south-1"
  }
}

# ============================================================================
# Example 4: Multi-Region ECR for Container Images
# ============================================================================

# ECR in us-east-1
resource "aws_ecr_repository" "app_us_east" {
  name                 = "app-us-east"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name   = "App Repository US East"
    Region = "us-east-1"
  }
}

# ECR in us-west-2
resource "aws_ecr_repository" "app_us_west" {
  provider             = aws.west
  name                 = "app-us-west"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name   = "App Repository US West"
    Region = "us-west-2"
  }
}

# ============================================================================
# Example 5: Multi-Region KMS Keys for Encryption
# ============================================================================

# KMS Key in us-east-1
resource "aws_kms_key" "us_east" {
  description             = "KMS key for US East"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name   = "US East KMS Key"
    Region = "us-east-1"
  }
}

# KMS Key in Mumbai
resource "aws_kms_key" "mumbai" {
  provider                = aws.mumbai
  description             = "KMS key for Mumbai"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name   = "Mumbai KMS Key"
    Region = "ap-south-1"
  }
}

# ============================================================================
# Example 6: Multi-Region CloudWatch Log Groups
# ============================================================================

# Log group in us-east-1
resource "aws_cloudwatch_log_group" "app_us_east" {
  name              = "/aws/app/us-east"
  retention_in_days = 7

  tags = {
    Name   = "App Logs US East"
    Region = "us-east-1"
  }
}

# Log group in Europe
resource "aws_cloudwatch_log_group" "app_europe" {
  provider          = aws.europe
  name              = "/aws/app/europe"
  retention_in_days = 7

  tags = {
    Name   = "App Logs Europe"
    Region = "eu-west-1"
  }
}

# Data source (works with default provider)
data "aws_caller_identity" "current" {}

# Data source with specific provider
data "aws_region" "west" {
  provider = aws.west
}

data "aws_region" "mumbai" {
  provider = aws.mumbai
}
