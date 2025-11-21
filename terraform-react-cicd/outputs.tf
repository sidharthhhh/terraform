# outputs.tf

output "cloudfront_distribution_domain_name" {
  description = "The URL for the deployed React application (use this in your browser)"
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

output "s3_hosting_bucket_name" {
  description = "The name of the S3 bucket hosting the static files"
  value       = aws_s3_bucket.frontend_hosting.bucket
}

output "codepipeline_url" {
  description = "The URL to view the pipeline in the AWS console"
  value       = "https://${var.aws_region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.pipeline.name}/view?region=${var.aws_region}"
}