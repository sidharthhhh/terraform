provider "aws" {
  region = var.aws_region
}

locals {
  # Map user selection to the AWS Lambda runtime identifier
  runtime_map = {
    "nodejs" = "nodejs20.x"
    "python" = "python3.12"
  }
  
  # Map user selection to the appropriate function handler
  handler_map = {
    "nodejs" = "index.handler"
    "python" = "lambda_function.lambda_handler"
  }

  # Map user selection to the sample source code file to bundle
  source_file_map = {
    "nodejs" = "index.js"
    "python" = "lambda_function.py"
  }

  # Selected values based on user input
  selected_runtime     = local.runtime_map[var.programming_language]
  selected_handler     = local.handler_map[var.programming_language]
  selected_source_file = local.source_file_map[var.programming_language]
}

# Zip the source code for deployment
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/${local.selected_source_file}"
  output_path = "${path.module}/lambda_payload.zip"
}

# Create the Lambda function
resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = local.selected_handler
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = local.selected_runtime
}

# IAM Role configuration
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.function_name}_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach basic execution role policy so Lambda can write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
