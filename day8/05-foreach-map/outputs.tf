output "all_buckets" {
  description = "All bucket names created"
  value       = { for key, bucket in aws_s3_bucket.buckets : key => bucket.bucket }
}

output "production_buckets" {
  description = "Only production buckets"
  value = {
    for key, config in var.buckets : key => aws_s3_bucket.buckets[key].bucket
    if config.environment == "production"
  }
}

output "versioned_buckets" {
  description = "Buckets with versioning enabled"
  value = {
    for key, bucket in aws_s3_bucket_versioning.versioning : key => aws_s3_bucket.buckets[key].bucket
  }
}

output "bucket_details" {
  description = "Detailed bucket information"
  value = {
    for key, bucket in aws_s3_bucket.buckets : key => {
      bucket_name        = bucket.bucket
      arn                = bucket.arn
      environment        = var.buckets[key].environment
      purpose            = var.buckets[key].purpose
      versioning_enabled = var.buckets[key].versioning_enabled
      lifecycle_days     = var.buckets[key].lifecycle_days
    }
  }
}

output "buckets_by_environment" {
  description = "Buckets grouped by environment"
  value = {
    production  = [for key, config in var.buckets : aws_s3_bucket.buckets[key].bucket if config.environment == "production"]
    development = [for key, config in var.buckets : aws_s3_bucket.buckets[key].bucket if config.environment == "development"]
  }
}

output "buckets_by_lifecycle" {
  description = "Bucket names with their lifecycle days"
  value = {
    for key, config in var.buckets : aws_s3_bucket.buckets[key].bucket => "${config.lifecycle_days} days"
  }
}

output "summary" {
  description = "Summary statistics"
  value = {
    total_buckets        = length(aws_s3_bucket.buckets)
    versioned_count      = length(aws_s3_bucket_versioning.versioning)
    production_count     = length([for k, v in var.buckets : k if v.environment == "production"])
    development_count    = length([for k, v in var.buckets : k if v.environment == "development"])
    long_retention_count = length([for k, v in var.buckets : k if v.lifecycle_days >= 365])
  }
}

output "specific_bucket_example" {
  description = "Example of accessing a specific bucket"
  value = {
    app_logs_name = aws_s3_bucket.buckets["app-logs"].bucket
    app_logs_arn  = aws_s3_bucket.buckets["app-logs"].arn
  }
}
