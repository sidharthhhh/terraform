# ============================================================================
# VARIABLES.TF - Input Variable Declarations
# ============================================================================
#
# PURPOSE:
# Declares all input variables used throughout the Terraform configuration.
# Variables make your code reusable and configurable for different environments.
#
# LOADING ORDER:
# Variable declarations are loaded early, then values are resolved from:
# 1. Command line: -var="key=value"
# 2. *.auto.tfvars files (alphabetically)
# 3. terraform.tfvars file
# 4. Environment variables: TF_VAR_name
# 5. Default values specified here
#
# VARIABLE TYPES:
# - string: Text values (e.g., "us-east-1")
# - number: Numeric values (e.g., 2)
# - bool: true or false
# - list: Ordered collection ["a", "b", "c"]
# - map: Key-value pairs {key1 = "value1", key2 = "value2"}
# - object: Complex structured data
#
# BEST PRACTICES:
# - Always add descriptions (helps with documentation)
# - Use validation rules when possible
# - Provide sensible defaults for optional variables
# - Group related variables together
# ============================================================================

# ----------------------------------------------------------------------------
# General Configuration Variables
# ----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"

  # Validation ensures only valid AWS regions are accepted
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod) for resource tagging"
  type        = string
  default     = "dev"

  # Validation restricts to specific environment names
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "terraform-day6"
}

# ----------------------------------------------------------------------------
# VPC and Network Configuration Variables
# ----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC (defines IP address range for the entire VPC)"
  type        = string
  default     = "10.0.0.0/16" # Provides 65,536 IP addresses

  # Validation ensures valid CIDR format
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (subnet with internet access)"
  type        = string
  default     = "10.0.1.0/24" # Provides 256 IP addresses

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Public subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet (subnet without direct internet access)"
  type        = string
  default     = "10.0.2.0/24" # Provides 256 IP addresses

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "Private subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zone" {
  description = "Availability Zone for subnet placement (leave empty for automatic selection)"
  type        = string
  default     = "" # Empty string means AWS will choose automatically
}

# ----------------------------------------------------------------------------
# EC2 Instance Configuration Variables
# ----------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type (defines CPU, memory, and network performance)"
  type        = string
  default     = "t2.micro" # Free tier eligible

  # Validation ensures only common instance types are used
  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium", "t3.micro", "t3.small"], var.instance_type)
    error_message = "Instance type must be a valid t2 or t3 type for this demo."
  }
}

variable "ami_filter_name" {
  description = "Name filter for AMI lookup (finds latest matching AMI)"
  type        = string
  default     = "amzn2-ami-hvm-*-x86_64-gp2" # Amazon Linux 2 pattern
}

variable "ami_owner" {
  description = "AWS account ID that owns the AMI (amazon = AWS official)"
  type        = string
  default     = "amazon" # Use Amazon's official AMIs
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 8 # Minimum recommended size

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 100
    error_message = "Root volume size must be between 8 and 100 GB."
  }
}

# ----------------------------------------------------------------------------
# Security Group Configuration Variables
# ----------------------------------------------------------------------------

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Open to world - restrict in production!

  # NOTE: In production, restrict to your IP or corporate network
  # Example: ["203.0.113.0/24"] for specific network
}

variable "allowed_http_cidr" {
  description = "CIDR blocks allowed to access HTTP (port 80)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Open to world for web access
}

variable "allowed_https_cidr" {
  description = "CIDR blocks allowed to access HTTPS (port 443)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Open to world for web access
}

variable "enable_ssh" {
  description = "Enable SSH access to EC2 instance"
  type        = bool
  default     = true
}

variable "enable_http" {
  description = "Enable HTTP access to EC2 instance"
  type        = bool
  default     = true
}

# ----------------------------------------------------------------------------
# Feature Flags (Advanced Pattern)
# ----------------------------------------------------------------------------

variable "enable_monitoring" {
  description = "Enable detailed CloudWatch monitoring for EC2 instance"
  type        = bool
  default     = false # Detailed monitoring costs extra
}

variable "create_private_subnet" {
  description = "Create a private subnet in addition to public subnet"
  type        = bool
  default     = false # Keep it simple for Day 6
}

# ============================================================================
# VARIABLE USAGE IN OTHER FILES:
# Once declared here, variables are referenced in other .tf files using:
# - var.variable_name
# Example: region = var.aws_region
#
# VARIABLE PRECEDENCE (highest to lowest):
# 1. -var or -var-file CLI flags
# 2. *.auto.tfvars (alphabetical order)
# 3. terraform.tfvars
# 4. Environment variables (TF_VAR_name)
# 5. Default values in this file
# 6. Interactive prompt (if no default and not provided)
# ============================================================================
