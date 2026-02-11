terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Variable to control whether to create resources
variable "create_buckets" {
  description = "Whether to create S3 buckets"
  type        = bool
  default     = true
}

# Variable for number of buckets
variable "bucket_count" {
  description = "Number of buckets to create"
  type        = number
  default     = 3

  validation {
    condition     = var.bucket_count >= 0 && var.bucket_count <= 10
    error_message = "Bucket count must be between 0 and 10."
  }
}

# Environment variable
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

# Conditional count: create resources only if create_buckets is true
resource "aws_s3_bucket" "conditional" {
  count = var.create_buckets ? var.bucket_count : 0

  bucket = "conditional-bucket-${var.environment}-${count.index}"

  tags = {
    Name        = "Conditional Bucket ${count.index}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Example: Create monitoring only in production
resource "aws_s3_bucket_logging" "example" {
  count = var.environment == "production" ? var.bucket_count : 0

  bucket = aws_s3_bucket.conditional[count.index].id

  target_bucket = aws_s3_bucket.conditional[count.index].id
  target_prefix = "log/"
}

# Example: Create lifecycle rules only for specific count
resource "aws_s3_bucket_lifecycle_configuration" "example" {
  # Only create for the first 2 buckets
  count = min(var.bucket_count, 2)

  bucket = aws_s3_bucket.conditional[count.index].id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}
