# 1. Create a "random string" to append to our bucket name to make it globally unique
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

# 2. Create the S3 Bucket
# This bucket is PRIVATE. We do not enable static website hosting on it.
resource "aws_s3_bucket" "website_bucket" {
  bucket = "${var.bucket_name_prefix}-${random_string.bucket_suffix.result}"

  tags = {
    Name = "Static Website Bucket"
  }
}

# 3. Create the "Origin Access Identity" (OAI)
# This is a special "CloudFront user" that can access the S3 bucket.
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for static website bucket"
}

# 4. Create the S3 Bucket Policy
# This policy "allows" the OAI to read objects from the bucket.
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# 5. Define the files to upload (MIME types are important!)
locals {
  files_to_upload = {
    "index.html" = "text/html"
    "style.css"  = "text/css"
  }
}

# 6. Upload all files from the 'website' folder
# This is efficient: it only re-uploads a file if the local content changes (md5 hash).
resource "aws_s3_object" "website_files" {
  for_each     = local.files_to_upload
  bucket       = aws_s3_bucket.website_bucket.id
  key          = each.key
  source       = "${path.module}/website/${each.key}"
  content_type = each.value

  # This ETag ensures the file is re-uploaded if you change it locally
  etag = filemd5("${path.module}/website/${each.key}")
}

# 7. Create the CloudFront Distribution (The CDN)
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = "S3-${var.bucket_name_prefix}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Default cache behavior
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-${var.bucket_name_prefix}"

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # This tells CloudFront to use the default SSL certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Wait for files to be uploaded before the distribution goes live
  depends_on = [aws_s3_object.website_files]

  tags = {
    Name = "Static Website CDN"
  }
}