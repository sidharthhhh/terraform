terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create 3 S3 buckets using count
resource "aws_s3_bucket" "example" {
  count = 3

  # Use count.index to make each bucket unique
  bucket = "my-terraform-bucket-${count.index}-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Bucket ${count.index}"
    Environment = "Development"
    ManagedBy   = "Terraform"
    Index       = count.index
  }
}

# Random ID to ensure bucket names are globally unique
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Enable versioning on all buckets
resource "aws_s3_bucket_versioning" "example" {
  count = 3

  # Reference the bucket using count.index
  bucket = aws_s3_bucket.example[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}
