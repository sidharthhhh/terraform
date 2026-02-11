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

# Example 1: Production Database - CRITICAL RESOURCE
# This database contains production data and should NEVER be accidentally destroyed
resource "aws_db_instance" "production" {
  identifier                = "production-database"
  engine                    = "postgres"
  engine_version            = "14.7"
  instance_class            = "db.t3.micro"
  allocated_storage         = 20
  storage_encrypted         = true
  db_name                   = "productiondb"
  username                  = "dbadmin"
  password                  = var.db_password # In real world, use AWS Secrets Manager
  skip_final_snapshot       = false
  final_snapshot_identifier = "production-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # PREVENT DESTROY: Terraform will ERROR if you try to destroy this
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Production Database"
    Environment = "production"
    Critical    = "true"
    ManagedBy   = "Terraform"
    Protection  = "prevent_destroy enabled"
  }
}

# Example 2: S3 Bucket with Critical Data
# Bucket contains important backups and logs
resource "aws_s3_bucket" "critical_backups" {
  bucket = "critical-backups-${data.aws_caller_identity.current.account_id}"

  # Stop accidental deletion of backup bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Critical Backups"
    Environment = "production"
    DataType    = "Backups"
    ManagedBy   = "Terraform"
    Protection  = "prevent_destroy enabled"
  }
}

# Enable versioning on critical bucket
resource "aws_s3_bucket_versioning" "critical_backups" {
  bucket = aws_s3_bucket.critical_backups.id

  versioning_configuration {
    status = "Enabled"
  }

  # Also protect versioning configuration
  lifecycle {
    prevent_destroy = true
  }
}

# Example 3: KMS Key for Encryption
# Destroying this would make encrypted data unreadable!
resource "aws_kms_key" "production_key" {
  description             = "Production encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  # Never accidentally destroy encryption keys!
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Production Encryption Key"
    Environment = "production"
    ManagedBy   = "Terraform"
    Protection  = "prevent_destroy enabled"
  }
}

resource "aws_kms_alias" "production_key" {
  name          = "alias/production-key"
  target_key_id = aws_kms_key.production_key.key_id
}

# Example 4: DynamoDB Table with Important Data
resource "aws_dynamodb_table" "user_data" {
  name         = "production-user-data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "timestamp"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  point_in_time_recovery {
    enabled = true
  }

  # Protect user data from accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Production User Data"
    Environment = "production"
    DataType    = "UserData"
    ManagedBy   = "Terraform"
    Protection  = "prevent_destroy enabled"
  }
}

# Example 5: EBS Volume with Critical Data
resource "aws_ebs_volume" "critical_data" {
  availability_zone = "us-east-1a"
  size              = 100
  type              = "gp3"
  encrypted         = true
  kms_key_id        = aws_kms_key.production_key.arn

  # Protect data volume from deletion
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Critical Data Volume"
    Environment = "production"
    ManagedBy   = "Terraform"
    Protection  = "prevent_destroy enabled"
  }
}

# Example 6: ECR Repository for Production Images
resource "aws_ecr_repository" "production_app" {
  name                 = "production-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # Protect production container images
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Production App Repository"
    Environment = "production"
    ManagedBy   = "Terraform"
    Protection  = "prevent_destroy enabled"
  }
}

# Variable for DB password (should use Secrets Manager in production)
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!" # For demo only!
}

# Data source
data "aws_caller_identity" "current" {}
