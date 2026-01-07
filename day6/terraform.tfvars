# ============================================================================
# TERRAFORM.TFVARS - Variable Value Assignments
# ============================================================================
#
# PURPOSE:
# Assigns actual values to variables declared in variables.tf.
# This file is environment-specific and should contain your actual configuration.
#
# LOADING ORDER:
# Automatically loaded by Terraform if named:
# - terraform.tfvars
# - terraform.tfvars.json
# - *.auto.tfvars
# - *.auto.tfvars.json
#
# SECURITY WARNING:
# This file often contains environment-specific or sensitive data.
# For real projects:
# 1. Add terraform.tfvars to .gitignore
# 2. Create terraform.tfvars.example as a template
# 3. Use different .tfvars files per environment (dev.tfvars, prod.tfvars)
#
# BEST PRACTICES:
# - Document why specific values are chosen
# - Use meaningful, descriptive values
# - Keep production values in separate files
# - Never commit secrets (use environment variables instead)
# ============================================================================

# ----------------------------------------------------------------------------
# General Configuration
# ----------------------------------------------------------------------------

# AWS Region - US East 1 (N. Virginia) is often cheapest and most feature-rich
aws_region = "us-east-1"

# Environment identifier - Used in tags and resource names
environment = "dev"

# Project name - Used for resource naming consistency
project_name = "terraform-day6"

# ----------------------------------------------------------------------------
# Network Configuration
# ----------------------------------------------------------------------------

# VPC CIDR - 10.0.0.0/16 provides 65,536 IP addresses
# This is a private IP range safe for internal use
vpc_cidr = "10.0.0.0/16"

# Public Subnet CIDR - 10.0.1.0/24 provides 256 IPs (251 usable)
# AWS reserves 5 IPs per subnet:
# - .0: Network address
# - .1: VPC router
# - .2: DNS server
# - .3: Future use
# - .255: Broadcast address
public_subnet_cidr = "10.0.1.0/24"

# Private Subnet CIDR - For future use (databases, app servers)
private_subnet_cidr = "10.0.2.0/24"

# Availability Zone - Leave empty for automatic selection
# AWS will choose the best AZ based on capacity and routing
# availability_zone = "us-east-1a"  # Uncomment to specify manually

# ----------------------------------------------------------------------------
# EC2 Instance Configuration
# ----------------------------------------------------------------------------

# Instance Type - t2.micro is free tier eligible (1 vCPU, 1GB RAM)
# Suitable for testing and learning
instance_type = "t2.micro"

# AMI Filter - Finds the latest Amazon Linux 2 AMI automatically
# Pattern matches: amzn2-ami-hvm-2.0.YYYYMMDD-x86_64-gp2
ami_filter_name = "amzn2-ami-hvm-*-x86_64-gp2"

# AMI Owner - "amazon" means use official Amazon AMIs
ami_owner = "amazon"

# Root Volume Size - 8GB is AWS minimum, sufficient for basic testing
root_volume_size = 8

# ----------------------------------------------------------------------------
# Security Configuration
# ----------------------------------------------------------------------------

# SSH Access - WARNING: 0.0.0.0/0 allows access from anywhere!
# PRODUCTION BEST PRACTICE: Restrict to your IP or VPN
# Example: allowed_ssh_cidr = ["203.0.113.25/32"]  # Single IP
allowed_ssh_cidr = ["0.0.0.0/0"]

# HTTP Access - Open to world for web server testing
allowed_http_cidr = ["0.0.0.0/0"]

# HTTPS Access - Open to world for secure web access
allowed_https_cidr = ["0.0.0.0/0"]

# Feature Toggles
enable_ssh  = true # Enable SSH for remote management
enable_http = true # Enable HTTP for web server

# ----------------------------------------------------------------------------
# Advanced Features
# ----------------------------------------------------------------------------

# CloudWatch Detailed Monitoring - Costs extra, disabled for learning
enable_monitoring = false

# Private Subnet Creation - Not needed for Day 6 simple setup
create_private_subnet = false

# ============================================================================
# ENVIRONMENT-SPECIFIC FILES PATTERN:
# For multi-environment deployments, create separate files:
#
# dev.tfvars:
#   instance_type = "t2.micro"
#   environment = "dev"
#
# prod.tfvars:
#   instance_type = "t3.medium"
#   environment = "prod"
#   allowed_ssh_cidr = ["10.0.0.0/8"]  # Restrict SSH
#
# Then apply with: terraform apply -var-file="prod.tfvars"
# ============================================================================
