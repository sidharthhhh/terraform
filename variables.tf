variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1" # MODIFIED: Set to Mumbai
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.small" # MODIFIED: Changed from t2.micro
}

variable "key_name" {
  description = "The name of the AWS EC2 Key Pair to use for SSH."
  type        = string
  default     = "terraform-key"
}

variable "my_ip" {
  description = "Your local IP address. This is used for the security group."
  type        = string
  default     = "0.0.0.0/0" # You should override this in terraform.tfvars
}

# --- NEW VARIABLES ---

variable "vpc_cidr" {
  description = "The CIDR block for the custom VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks for the public subnets. Must be in different AZs."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}