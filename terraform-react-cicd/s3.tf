# s3.tf

# 1. Pipeline Artifacts Bucket
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${var.project_name}-artifacts-${var.aws_region}"
  # The encryption block is intentionally removed here to fix the deprecation warning.

  force_destroy = true
}

# New Resource: Manages the encryption configuration for the Artifacts Bucket
# This is required for CodePipeline compatibility.
resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_encryption" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 2. Frontend Hosting Bucket
resource "aws_s3_bucket" "frontend_hosting" {
  bucket = "${var.project_name}-frontend-hosting-${var.aws_region}"

  force_destroy = true
}

# Enable Versioning
resource "aws_s3_bucket_versioning" "frontend_hosting_versioning" {
  bucket = aws_s3_bucket.frontend_hosting.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. CloudFront Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for CloudFront to S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}