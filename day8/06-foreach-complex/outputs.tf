output "all_buckets" {
  description = "All S3 buckets created"
  value = {
    for key, bucket in aws_s3_bucket.app_buckets : key => {
      name = bucket.bucket
      arn  = bucket.arn
    }
  }
}

output "buckets_by_stack" {
  description = "Buckets grouped by application stack"
  value = {
    for stack_key in keys(var.application_stacks) : stack_key => {
      for bucket_key, bucket in aws_s3_bucket.app_buckets :
      bucket_key => bucket.bucket
      if startswith(bucket_key, stack_key)
    }
  }
}

output "ecr_repositories" {
  description = "All ECR repositories"
  value = {
    for key, repo in aws_ecr_repository.app_repos : key => {
      name        = repo.name
      url         = repo.repository_url
      registry_id = repo.registry_id
    }
  }
}

output "repositories_by_stack" {
  description = "ECR repositories grouped by stack"
  value = {
    for stack_key in keys(var.application_stacks) : stack_key => [
      for repo_key, repo in aws_ecr_repository.app_repos :
      repo.repository_url
      if startswith(repo_key, stack_key)
    ]
  }
}

output "versioned_buckets" {
  description = "Buckets with versioning enabled"
  value       = keys(aws_s3_bucket_versioning.app_bucket_versioning)
}

output "encrypted_buckets" {
  description = "Buckets with encryption enabled"
  value       = keys(aws_s3_bucket_server_side_encryption_configuration.app_bucket_encryption)
}

output "db_config_parameters" {
  description = "SSM parameter names for database configs"
  value = {
    for key, param in aws_ssm_parameter.db_configs : key => param.name
  }
}

output "iam_roles" {
  description = "IAM roles created per stack"
  value = {
    for key, role in aws_iam_role.stack_roles : key => {
      name = role.name
      arn  = role.arn
    }
  }
}

output "sns_topics" {
  description = "SNS topics for notifications"
  value = {
    for key, topic in aws_sns_topic.stack_notifications : key => {
      name = topic.name
      arn  = topic.arn
    }
  }
}

output "stack_summary" {
  description = "Summary of resources per stack"
  value = {
    for stack_key in keys(var.application_stacks) : stack_key => {
      environment  = var.application_stacks[stack_key].environment
      buckets      = length([for k in keys(aws_s3_bucket.app_buckets) : k if startswith(k, stack_key)])
      repositories = length([for k in keys(aws_ecr_repository.app_repos) : k if startswith(k, stack_key)])
      iam_role     = aws_iam_role.stack_roles[stack_key].name
      sns_topic    = aws_sns_topic.stack_notifications[stack_key].name
    }
  }
}

output "production_resources" {
  description = "All production resources"
  value = {
    buckets = [
      for key, bucket in aws_s3_bucket.app_buckets :
      bucket.bucket
      if contains(split("-", key), "prod")
    ]
    repositories = [
      for key, repo in aws_ecr_repository.app_repos :
      repo.name
      if contains(split("-", key), "prod")
    ]
  }
}
