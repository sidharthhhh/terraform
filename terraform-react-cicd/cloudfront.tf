# cloudfront.tf

# Frontend S3 Origin ID
locals {
  s3_origin_id = "S3-Frontend-Hosting-Origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for ${var.project_name} React App"
  default_root_object = "index.html" # Essential for React SPA

  origin {
    domain_name              = aws_s3_bucket.frontend_hosting.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true
    forwarded_values {
      # Setting query_string to false is usually better for SPAs unless needed
      query_string = false 
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Custom Error Pages for SPAs (ensures /about loads index.html)
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
}

# --- ADDED POLICY LOGIC BELOW ---

# 1. The Policy Document (Data Source)
data "aws_iam_policy_document" "s3_oac_policy" {
  statement {
    sid    = "AllowCloudFrontOAC"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.frontend_hosting.arn}/*",
      aws_s3_bucket.frontend_hosting.arn,
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

# 2. Applying the Policy to the Bucket
resource "aws_s3_bucket_policy" "frontend_hosting_policy" {
  bucket = aws_s3_bucket.frontend_hosting.id
  policy = data.aws_iam_policy_document.s3_oac_policy.json
}