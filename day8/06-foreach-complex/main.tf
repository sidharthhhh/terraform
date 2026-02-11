terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Complex nested map structure representing a complete application stack
variable "application_stacks" {
  description = "Complete application stack configurations"
  type = map(object({
    environment = string
    vpc_cidr    = string
    buckets = map(object({
      versioning     = bool
      encryption     = bool
      lifecycle_days = number
    }))
    repositories = set(string)
    db_config = object({
      engine         = string
      instance_class = string
      storage_gb     = number
    })
  }))
  default = {
    "web-app-prod" = {
      environment = "production"
      vpc_cidr    = "10.0.0.0/16"
      buckets = {
        "assets" = {
          versioning     = true
          encryption     = true
          lifecycle_days = 90
        }
        "logs" = {
          versioning     = true
          encryption     = true
          lifecycle_days = 30
        }
      }
      repositories = ["frontend", "backend", "api"]
      db_config = {
        engine         = "postgres"
        instance_class = "db.t3.medium"
        storage_gb     = 100
      }
    }
    "web-app-staging" = {
      environment = "staging"
      vpc_cidr    = "10.1.0.0/16"
      buckets = {
        "assets" = {
          versioning     = false
          encryption     = true
          lifecycle_days = 7
        }
      }
      repositories = ["frontend", "backend"]
      db_config = {
        engine         = "postgres"
        instance_class = "db.t3.small"
        storage_gb     = 20
      }
    }
  }
}

# Create S3 buckets using nested for_each
resource "aws_s3_bucket" "app_buckets" {
  # Flatten the nested structure
  for_each = merge([
    for stack_key, stack in var.application_stacks : {
      for bucket_key, bucket_config in stack.buckets :
      "${stack_key}-${bucket_key}" => {
        stack_name  = stack_key
        bucket_key  = bucket_key
        environment = stack.environment
        config      = bucket_config
      }
    }
  ]...)

  bucket = "${each.value.stack_name}-${each.value.bucket_key}-${each.value.environment}"

  tags = {
    Name        = "${each.value.stack_name}-${each.value.bucket_key}"
    Stack       = each.value.stack_name
    BucketType  = each.value.bucket_key
    Environment = each.value.environment
    ManagedBy   = "Terraform"
  }
}

# Conditional versioning based on nested config
resource "aws_s3_bucket_versioning" "app_bucket_versioning" {
  for_each = {
    for key, bucket in aws_s3_bucket.app_buckets : key => bucket
    if merge([
      for stack_key, stack in var.application_stacks : {
        for bucket_key, bucket_config in stack.buckets :
        "${stack_key}-${bucket_key}" => bucket_config
      }
    ]...)[key].versioning
  }

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Conditional encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_bucket_encryption" {
  for_each = {
    for key, value in merge([
      for stack_key, stack in var.application_stacks : {
        for bucket_key, bucket_config in stack.buckets :
        "${stack_key}-${bucket_key}" => bucket_config
      }
    ]...) : key => value
    if value.encryption
  }

  bucket = aws_s3_bucket.app_buckets[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create ECR repositories for each stack
resource "aws_ecr_repository" "app_repos" {
  # Flatten stacks and repositories
  for_each = merge([
    for stack_key, stack in var.application_stacks : {
      for repo in stack.repositories :
      "${stack_key}-${repo}" => {
        stack_name  = stack_key
        repo_name   = repo
        environment = stack.environment
      }
    }
  ]...)

  name = "${each.value.stack_name}-${each.value.repo_name}"

  image_scanning_configuration {
    scan_on_push = each.value.environment == "production" ? true : false
  }

  tags = {
    Name        = "${each.value.stack_name}-${each.value.repo_name}"
    Stack       = each.value.stack_name
    Repository  = each.value.repo_name
    Environment = each.value.environment
    ManagedBy   = "Terraform"
  }
}

# Create parameter store entries for DB configs
resource "aws_ssm_parameter" "db_configs" {
  for_each = var.application_stacks

  name        = "/${each.key}/database/config"
  description = "Database configuration for ${each.key}"
  type        = "SecureString"

  value = jsonencode({
    engine         = each.value.db_config.engine
    instance_class = each.value.db_config.instance_class
    storage_gb     = each.value.db_config.storage_gb
  })

  tags = {
    Stack       = each.key
    Environment = each.value.environment
    Type        = "DatabaseConfig"
    ManagedBy   = "Terraform"
  }
}

# Create SNS topics for each stack with dynamic subscription
resource "aws_sns_topic" "stack_notifications" {
  for_each = var.application_stacks

  name = "${each.key}-notifications"

  tags = {
    Stack       = each.key
    Environment = each.value.environment
    ManagedBy   = "Terraform"
  }
}

# IAM roles per stack with dynamic policies
resource "aws_iam_role" "stack_roles" {
  for_each = var.application_stacks

  name = "${each.key}-application-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Stack       = each.key
    Environment = each.value.environment
    ManagedBy   = "Terraform"
  }
}

# Attach policies to access their own stack's S3 buckets
resource "aws_iam_role_policy" "stack_s3_access" {
  for_each = var.application_stacks

  name = "${each.key}-s3-access"
  role = aws_iam_role.stack_roles[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          for bucket_key in keys(each.value.buckets) :
          "${aws_s3_bucket.app_buckets["${each.key}-${bucket_key}"].arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          for bucket_key in keys(each.value.buckets) :
          aws_s3_bucket.app_buckets["${each.key}-${bucket_key}"].arn
        ]
      }
    ]
  })
}
