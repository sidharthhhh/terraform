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

# Example 1: Auto Scaling Group - Ignore desired_capacity
# ASG auto-scales based on metrics, don't let Terraform revert changes
resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  min_size            = 2
  max_size            = 10
  desired_capacity    = 3 # Initial value
  vpc_zone_identifier = [aws_subnet.public.id]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Ignore changes to desired_capacity
  # ASG will scale this up/down, we don't want Terraform to reset it
  lifecycle {
    ignore_changes = [
      desired_capacity,
      # Also ignore load_balancers if added manually
      load_balancers,
      target_group_arns
    ]
  }

  tag {
    key                 = "Name"
    value               = "App Server"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }
}

# Example 2: EC2 Instance - Ignore tags added by external systems
# AWS Systems Manager or other tools might add tags
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  tags = {
    Name      = "Web Server"
    ManagedBy = "Terraform"
    # Other tools might add: SSMManaged, Backup, Monitoring, etc.
  }

  # Ignore tags added by external systems
  lifecycle {
    ignore_changes = [
      tags["SSMManaged"],
      tags["BackupPolicy"],
      tags["MonitoringEnabled"],
      tags["LastPatched"]
    ]
  }
}

# Example 3: Lambda Function - Ignore function code updates
# Developers deploy code directly, don't change it with Terraform
resource "aws_lambda_function" "app" {
  filename      = "lambda_function.zip" # Initial deployment
  function_name = "app-function"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = var.log_level
    }
  }

  # Ignore code changes - deployed via CI/CD
  # Also ignore environment variables that might be updated via console
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      last_modified,
      # Ignore specific env vars that ops team changes
      environment[0].variables["DEBUG_MODE"]
    ]
  }

  tags = {
    Name      = "App Lambda Function"
    ManagedBy = "Terraform"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Example 4: RDS Instance - Ignore password changes
# Passwords might be rotated by AWS Secrets Manager
resource "aws_db_instance" "app" {
  identifier          = "app-database"
  engine              = "postgres"
  engine_version      = "14.7"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "appdb"
  username            = "dbadmin"
  password            = var.initial_db_password
  skip_final_snapshot = true

  # Ignore password - rotated by Secrets Manager
  lifecycle {
    ignore_changes = [
      password,
      # Also ignore minor version upgrades done automatically
      engine_version
    ]
  }

  tags = {
    Name      = "App Database"
    ManagedBy = "Terraform"
  }
}

# Example 5: S3 Bucket - Ignore lifecycle rules managed elsewhere
resource "aws_s3_bucket" "data" {
  bucket = "app-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name      = "App Data Bucket"
    ManagedBy = "Terraform"
  }
}

# Lifecycle rules might be managed by governance tools
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    expiration {
      days = 90
    }
  }

  # Governance tool might add/modify rules
  lifecycle {
    ignore_changes = [rule]
  }
}

# Example 6: Security Group - Ignore rules added for debugging
resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Application security group"
  vpc_id      = aws_vpc.main.id

  # Base rules defined here
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ops team might add temporary debugging rules
  lifecycle {
    ignore_changes = [
      ingress,
      egress
    ]
  }

  tags = {
    Name      = "App Security Group"
    ManagedBy = "Terraform"
  }
}

# Supporting resources
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "Main VPC"
    ManagedBy = "Terraform"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "Public Subnet"
    ManagedBy = "Terraform"
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name      = "App Server"
      ManagedBy = "Terraform"
    }
  }
}

# Variables
variable "instance_type" {
  default = "t2.micro"
}

variable "log_level" {
  default = "INFO"
}

variable "initial_db_password" {
  description = "Initial database password"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}

# Data sources
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_caller_identity" "current" {}
