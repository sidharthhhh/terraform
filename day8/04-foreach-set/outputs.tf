output "bucket_names" {
  description = "List of all bucket names created"
  value       = values(aws_s3_bucket.buckets)[*].bucket
}

output "bucket_arns" {
  description = "Map of bucket name to ARN"
  value = {
    for key, bucket in aws_s3_bucket.buckets : key => bucket.arn
  }
}

output "bucket_ids" {
  description = "Map of bucket name to ID"
  value = {
    for key, bucket in aws_s3_bucket.buckets : key => bucket.id
  }
}

output "iam_user_names" {
  description = "List of IAM user names"
  value       = values(aws_iam_user.users)[*].name
}

output "iam_user_arns" {
  description = "Map of username to ARN"
  value = {
    for key, user in aws_iam_user.users : key => user.arn
  }
}

output "all_bucket_details" {
  description = "All bucket details"
  value = {
    for key, bucket in aws_s3_bucket.buckets : key => {
      id             = bucket.id
      arn            = bucket.arn
      bucket_name    = bucket.bucket
      hosted_zone_id = bucket.hosted_zone_id
      region         = bucket.region
    }
  }
}

output "resource_counts" {
  description = "Count of resources created"
  value = {
    buckets = length(aws_s3_bucket.buckets)
    users   = length(aws_iam_user.users)
  }
}

# Example: Access specific bucket by key
output "specific_bucket_example" {
  description = "Example of accessing specific bucket by key"
  value       = aws_s3_bucket.buckets["application-logs"].bucket
}
