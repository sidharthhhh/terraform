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

# Map of bucket configurations
variable "buckets" {
  description = "Map of S3 buckets with their configurations"
  type = map(object({
    versioning_enabled = bool
    lifecycle_days     = number
    environment        = string
    purpose            = string
  }))
  default = {
    "app-logs" = {
      versioning_enabled = true
      lifecycle_days     = 30
      environment        = "production"
      purpose            = "application-logs"
    }
    "user-data" = {
      versioning_enabled = true
      lifecycle_days     = 90
      environment        = "production"
      purpose            = "user-uploads"
    }
    "temp-storage" = {
      versioning_enabled = false
      lifecycle_days     = 7
      environment        = "development"
      purpose            = "temporary-files"
    }
    "backups" = {
      versioning_enabled = true
      lifecycle_days     = 365
      environment        = "production"
      purpose            = "database-backups"
    }
  }
}

# Map of environment-specific tags
variable "environment_tags" {
  description = "Additional tags per environment"
  type        = map(map(string))
  default = {
    production = {
      Compliance = "Required"
      Monitoring = "24x7"
      Backup     = "Daily"
    }
    development = {
      Compliance = "Optional"
      Monitoring = "Business Hours"
      Backup     = "Weekly"
    }
  }
}

# Create S3 buckets using for_each with map
resource "aws_s3_bucket" "buckets" {
  for_each = var.buckets

  bucket = "${each.key}-${each.value.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    {
      Name              = each.key
      Environment       = each.value.environment
      Purpose           = each.value.purpose
      VersioningEnabled = tostring(each.value.versioning_enabled)
      LifecycleDays     = tostring(each.value.lifecycle_days)
      ManagedBy         = "Terraform"
    },
    var.environment_tags[each.value.environment]
  )
}

# Conditionally enable versioning based on map values
resource "aws_s3_bucket_versioning" "versioning" {
  for_each = {
    for key, config in var.buckets : key => config
    if config.versioning_enabled
  }

  bucket = aws_s3_bucket.buckets[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Add lifecycle rules to all buckets
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  for_each = var.buckets

  bucket = aws_s3_bucket.buckets[each.key].id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    expiration {
      days = each.value.lifecycle_days
    }

    noncurrent_version_expiration {
      noncurrent_days = each.value.lifecycle_days / 2
    }
  }

  # Add intelligent tiering for production buckets
  dynamic "rule" {
    for_each = each.value.environment == "production" ? [1] : []

    content {
      id     = "intelligent-tiering"
      status = "Enabled"

      transition {
        days          = 30
        storage_class = "INTELLIGENT_TIERING"
      }
    }
  }
}

# Public access block for all buckets
resource "aws_s3_bucket_public_access_block" "pab" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Data source
data "aws_caller_identity" "current" {}
