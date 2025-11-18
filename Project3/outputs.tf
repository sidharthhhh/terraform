output "website_url" {
  description = "The URL of the CloudFront distribution. This is your public website URL."
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

output "s3_bucket_name" {
  description = "The full, unique name of the S3 bucket."
  value       = aws_s3_bucket.website_bucket.id
}