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

# List of bucket configurations
variable "bucket_configs" {
  description = "List of bucket names to create"
  type        = list(string)
  default = [
    "data-lake",
    "backups",
    "logs",
    "archives"
  ]
}

# List of users to create
variable "iam_users" {
  description = "List of IAM users to create"
  type        = list(string)
  default = [
    "alice",
    "bob",
    "charlie"
  ]
}

# List of bucket configurations with properties
variable "advanced_bucket_configs" {
  description = "Advanced bucket configurations"
  type = list(object({
    name           = string
    versioning     = bool
    lifecycle_days = number
  }))
  default = [
    {
      name           = "production-data"
      versioning     = true
      lifecycle_days = 30
    },
    {
      name           = "staging-data"
      versioning     = false
      lifecycle_days = 7
    },
    {
      name           = "development-data"
      versioning     = false
      lifecycle_days = 3
    }
  ]
}

# Create buckets from simple list
resource "aws_s3_bucket" "simple_buckets" {
  count = length(var.bucket_configs)

  bucket = "${var.bucket_configs[count.index]}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name      = var.bucket_configs[count.index]
    ManagedBy = "Terraform"
  }
}

# Create IAM users from list
resource "aws_iam_user" "users" {
  count = length(var.iam_users)

  name = var.iam_users[count.index]

  tags = {
    Name      = var.iam_users[count.index]
    ManagedBy = "Terraform"
  }
}

# Create advanced buckets with object list
resource "aws_s3_bucket" "advanced_buckets" {
  count = length(var.advanced_bucket_configs)

  bucket = "${var.advanced_bucket_configs[count.index].name}-adv-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name          = var.advanced_bucket_configs[count.index].name
    Versioning    = var.advanced_bucket_configs[count.index].versioning
    LifecycleDays = var.advanced_bucket_configs[count.index].lifecycle_days
    ManagedBy     = "Terraform"
  }
}

# Enable versioning conditionally
resource "aws_s3_bucket_versioning" "advanced" {
  count = length([
    for config in var.advanced_bucket_configs : config if config.versioning
  ])

  bucket = aws_s3_bucket.advanced_buckets[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle configuration based on object properties
resource "aws_s3_bucket_lifecycle_configuration" "advanced" {
  count = length(var.advanced_bucket_configs)

  bucket = aws_s3_bucket.advanced_buckets[count.index].id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    expiration {
      days = var.advanced_bucket_configs[count.index].lifecycle_days
    }
  }
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}
