output "simple_bucket_names" {
  description = "Simple bucket names created"
  value       = aws_s3_bucket.simple_buckets[*].bucket
}

output "iam_user_names" {
  description = "IAM users created"
  value       = aws_iam_user.users[*].name
}

output "iam_user_arns" {
  description = "IAM user ARNs"
  value       = aws_iam_user.users[*].arn
}

output "advanced_bucket_details" {
  description = "Advanced bucket details"
  value = {
    for idx, bucket in aws_s3_bucket.advanced_buckets :
    var.advanced_bucket_configs[idx].name => {
      bucket_name    = bucket.bucket
      arn            = bucket.arn
      versioning     = var.advanced_bucket_configs[idx].versioning
      lifecycle_days = var.advanced_bucket_configs[idx].lifecycle_days
    }
  }
}

output "versioned_buckets_count" {
  description = "Number of buckets with versioning enabled"
  value = length([
    for config in var.advanced_bucket_configs : config if config.versioning
  ])
}

output "total_resources_created" {
  description = "Total number of resources created"
  value = {
    simple_buckets   = length(aws_s3_bucket.simple_buckets)
    iam_users        = length(aws_iam_user.users)
    advanced_buckets = length(aws_s3_bucket.advanced_buckets)
  }
}

output "bucket_lifecycle_summary" {
  description = "Summary of bucket lifecycle configurations"
  value = {
    for idx, config in var.advanced_bucket_configs :
    config.name => "${config.lifecycle_days} days"
  }
}
