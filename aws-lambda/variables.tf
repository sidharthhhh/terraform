variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "ap-south-1"
}

variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "programming_language" {
  description = "Select the programming language (Options: 'nodejs' or 'python')"
  type        = string

  validation {
    condition     = contains(["nodejs", "python"], var.programming_language)
    error_message = "The programming language must be exactly 'nodejs' or 'python'."
  }
}
