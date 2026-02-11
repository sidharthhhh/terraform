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

# Set of bucket names
variable "bucket_names" {
  description = "Set of S3 bucket names to create"
  type        = set(string)
  default = [
    "application-logs",
    "user-uploads",
    "static-assets",
    "database-backups"
  ]
}

# Set of IAM user names
variable "iam_user_names" {
  description = "Set of IAM users to create"
  type        = set(string)
  default = [
    "developer",
    "devops",
    "qa-engineer"
  ]
}

# Create S3 buckets using for_each with a set
resource "aws_s3_bucket" "buckets" {
  for_each = var.bucket_names

  # each.key and each.value are the same for sets
  bucket = "${each.key}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name      = each.key
    ManagedBy = "Terraform"
    Type      = "for_each-set"
  }
}

# Create IAM users using for_each
resource "aws_iam_user" "users" {
  for_each = var.iam_user_names

  name = each.value

  tags = {
    Name      = each.value
    ManagedBy = "Terraform"
  }
}

# Enable versioning on all buckets
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Create bucket public access block
resource "aws_s3_bucket_public_access_block" "bucket_pab" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Data source to get current AWS account
data "aws_caller_identity" "current" {}
