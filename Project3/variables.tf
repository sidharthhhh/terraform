variable "aws_region" {
  description = "The AWS region to deploy in."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name_prefix" {
  description = "The prefix for the S3 bucket. A random suffix will be added."
  type        = string
  default     = "my-static-website"
}