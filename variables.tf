variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of the AWS EC2 Key Pair to use for SSH."
  type        = string
  default     = "terraform-key" # Matches the key you uploaded
}

variable "my_ip" {
  description = "Your local IP address. This is used for the security group."
  type        = string
  default     = "0.0.0.0/0"
}