output "website_url" {
  description = "Static website URL"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.website.bucket
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.website.arn
}

output "dependency_order" {
  description = "Resource creation order"
  value       = <<-EOT
    1. aws_s3_bucket.website
    2. aws_s3_bucket_public_access_block.website_pab (must happen before policy)
    3. aws_s3_bucket_policy.website_policy (depends_on: PAB)
    4. aws_s3_bucket_website_configuration.website (depends_on: policy)
    5. aws_s3_object.index (depends_on: website config)
  EOT
}
