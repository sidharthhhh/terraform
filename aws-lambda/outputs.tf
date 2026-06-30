output "lambda_function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "The Amazon Resource Name (ARN) of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "lambda_runtime_used" {
  description = "The runtime that was dynamically selected."
  value       = aws_lambda_function.this.runtime
}
