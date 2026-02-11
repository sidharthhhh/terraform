output "buckets_created" {
  description = "Whether buckets were created"
  value       = var.create_buckets
}

output "bucket_count" {
  description = "Number of buckets created"
  value       = length(aws_s3_bucket.conditional)
}

output "bucket_names" {
  description = "Names of created buckets"
  value       = aws_s3_bucket.conditional[*].bucket
}

output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "logging_enabled_count" {
  description = "Number of buckets with logging enabled"
  value       = length(aws_s3_bucket_logging.example)
}

output "lifecycle_rules_count" {
  description = "Number of buckets with lifecycle rules"
  value       = length(aws_s3_bucket_lifecycle_configuration.example)
}
