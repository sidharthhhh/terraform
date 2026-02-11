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

# IAM Role that must be created before Lambda
resource "aws_iam_role" "lambda_role" {
  name = "demo-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name      = "Lambda Execution Role"
    ManagedBy = "Terraform"
  }
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach S3 read policy
resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# S3 bucket for Lambda code
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "lambda-deployment-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name      = "Lambda Deployment Bucket"
    ManagedBy = "Terraform"
  }
}

# CloudWatch Log Group (must exist before Lambda)
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/demo-function"
  retention_in_days = 7

  tags = {
    Name      = "Lambda Logs"
    ManagedBy = "Terraform"
  }
}

# VPC for Lambda
resource "aws_vpc" "lambda_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "Lambda VPC"
    ManagedBy = "Terraform"
  }
}

# Subnet for Lambda
resource "aws_subnet" "lambda_subnet" {
  vpc_id            = aws_vpc.lambda_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name      = "Lambda Subnet"
    ManagedBy = "Terraform"
  }
}

# Security Group for Lambda
resource "aws_security_group" "lambda_sg" {
  name        = "lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = aws_vpc.lambda_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "Lambda Security Group"
    ManagedBy = "Terraform"
  }
}

# Lambda function with MULTIPLE explicit dependencies
resource "aws_lambda_function" "demo" {
  filename      = "${path.module}/lambda_function.zip"
  function_name = "demo-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  vpc_config {
    subnet_ids         = [aws_subnet.lambda_subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.lambda_bucket.id
    }
  }

  # Multiple explicit dependencies
  # Lambda needs:
  # 1. IAM policies to be attached (not just role created)
  # 2. Log group to exist (Lambda won't create it, will fail)
  # 3. VPC/Subnet/SG to be fully configured
  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_s3,
    aws_cloudwatch_log_group.lambda_logs,
    aws_vpc.lambda_vpc,
    aws_subnet.lambda_subnet,
    aws_security_group.lambda_sg
  ]

  tags = {
    Name      = "Demo Lambda Function"
    ManagedBy = "Terraform"
  }
}

# Create a dummy Lambda package
resource "null_resource" "lambda_package" {
  provisioner "local-exec" {
    command     = <<-EOT
      mkdir -p ${path.module}/lambda_temp
      echo 'exports.handler = async (event) => { return { statusCode: 200, body: "Hello!" }; };' > ${path.module}/lambda_temp/index.js
      cd ${path.module}/lambda_temp && tar -czf ../lambda_function.zip index.js
      rm -rf ${path.module}/lambda_temp
    EOT
    interpreter = ["bash", "-c"]
  }

  triggers = {
    always_run = timestamp()
  }
}

# SNS Topic
resource "aws_sns_topic" "alerts" {
  name = "lambda-alerts"

  tags = {
    Name      = "Lambda Alerts"
    ManagedBy = "Terraform"
  }
}

# Lambda permission for SNS (depends on both Lambda and SNS)
resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.demo.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn

  # Must wait for both resources to be ready
  depends_on = [
    aws_lambda_function.demo,
    aws_sns_topic.alerts
  ]
}

# Data source
data "aws_caller_identity" "current" {}
