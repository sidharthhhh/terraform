terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashimorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create an S3 bucket for website hosting
resource "aws_s3_bucket" "website" {
  bucket = "my-static-website-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name      = "Static Website Bucket"
    ManagedBy = "Terraform"
  }
}

# Create an IAM policy document for S3 bucket
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid = "PublicReadGetObject"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.website.arn}/*",
    ]
  }
}

# Attach bucket policy
# This has a HIDDEN dependency on the bucket policy being created
# Terraform can't automatically detect this
resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_policy.json

  # depends_on ensures public access block is disabled first
  depends_on = [
    aws_s3_bucket_public_access_block.website_pab
  ]
}

# Disable public access block (must happen before policy attachment)
resource "aws_s3_bucket_public_access_block" "website_pab" {
  bucket = aws_s3_bucket.website.id

  # Allow public access for website
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Configure bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  # This resource can only work after the bucket policy is in place
  # Although it references the bucket, it has a hidden dependency
  # on the policy being active
  depends_on = [
    aws_s3_bucket_policy.website_policy
  ]
}

# Upload index.html
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content      = "<html><body><h1>Hello from Terraform!</h1></body></html>"
  content_type = "text/html"

  # Wait for website configuration to be complete
  depends_on = [
    aws_s3_bucket_website_configuration.website
  ]
}

# Data source to get current AWS account
data "aws_caller_identity" "current" {}
