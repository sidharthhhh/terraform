# Outputs for Count Basic Example

# Output all bucket names as a list
output "bucket_names" {
  description = "List of all bucket names"
  value       = aws_s3_bucket.example[*].bucket
}

# Output all bucket ARNs
output "bucket_arns" {
  description = "List of all bucket ARNs"
  value       = aws_s3_bucket.example[*].arn
}

# Output individual bucket (first one)
output "first_bucket" {
  description = "The first bucket name"
  value       = aws_s3_bucket.example[0].bucket
}

# Output count of buckets created
output "bucket_count" {
  description = "Total number of buckets created"
  value       = length(aws_s3_bucket.example)
}

# Output bucket IDs mapped to their index
output "bucket_index_map" {
  description = "Map of index to bucket name"
  value = {
    for idx, bucket in aws_s3_bucket.example : idx => bucket.bucket
  }
}
