variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (dev, stage, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum size of ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum size of ASG"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired capacity of ASG"
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (Cost Saving for Dev)"
  type        = bool
  default     = true
}

variable "enable_spot_instances" {
  description = "Enable Spot Instances for ASG"
  type        = bool
  default     = false
}

variable "traffic_type" {
  description = "Scaling profile: 'low', 'medium', 'high', or 'custom'"
  type        = string
  default     = "custom"
  validation {
    condition     = contains(["low", "medium", "high", "custom"], var.traffic_type)
    error_message = "traffic_type must be one of: low, medium, high, custom."
  }
}

variable "certificate_arn" {
  description = "ACM Certificate ARN for HTTPS (Optional)"
  type        = string
  default     = ""
}
