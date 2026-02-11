output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.demo.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.demo.arn
}

output "lambda_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_role.arn
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "s3_bucket_name" {
  description = "S3 bucket for Lambda deployment"
  value       = aws_s3_bucket.lambda_bucket.id
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = aws_sns_topic.alerts.arn
}

output "dependency_graph" {
  description = "Visual representation of dependencies"
  value       = <<-EOT
    Dependency Graph:
    
    1. IAM Role (aws_iam_role.lambda_role)
       ├─→ 2a. Policy Attachment: Basic (aws_iam_role_policy_attachment.lambda_basic)
       └─→ 2b. Policy Attachment: S3 (aws_iam_role_policy_attachment.lambda_s3)
    
    3. CloudWatch Log Group (aws_cloudwatch_log_group.lambda_logs)
    
    4. VPC Resources:
       ├─→ VPC (aws_vpc.lambda_vpc)
       ├─→ Subnet (aws_subnet.lambda_subnet)
       └─→ Security Group (aws_security_group.lambda_sg)
    
    5. S3 Bucket (aws_s3_bucket.lambda_bucket)
    
    6. Lambda Function (depends_on ALL above)
       └─→ depends_on: [2a, 2b, 3, 4]
    
    7. SNS Topic (aws_sns_topic.alerts)
    
    8. Lambda Permission (depends_on Lambda + SNS)
       └─→ depends_on: [6, 7]
  EOT
}

output "why_depends_on_needed" {
  description = "Explanation of why depends_on is required"
  value = {
    iam_policies      = "Lambda needs policies ATTACHED, not just role created. Without depends_on, Lambda might create before policies are attached."
    log_group         = "Lambda expects log group to exist. If Lambda creates it, permissions might be wrong."
    vpc_resources     = "VPC, subnet, and security group must be fully configured before Lambda can use them."
    lambda_permission = "Permission requires both Lambda and SNS to be fully created and operational."
  }
}
