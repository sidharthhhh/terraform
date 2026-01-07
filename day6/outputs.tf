# ============================================================================
# OUTPUTS.TF - Output Values
# ============================================================================
#
# PURPOSE:
# Outputs expose values from your Terraform configuration.
# They are displayed after 'terraform apply' and can be queried anytime.
#
# USE CASES:
# 1. Display important information (IPs, URLs, IDs)
# 2. Pass values to other Terraform configurations (remote state)
# 3. Use in scripts and automation
# 4. Share information with team members
#
# QUERYING OUTPUTS:
# - View all outputs: terraform output
# - View specific output: terraform output vpc_id
# - JSON format: terraform output -json
#
# BEST PRACTICES:
# - Add descriptions to explain what each output represents
# - Mark sensitive outputs (passwords, keys) as sensitive
# - Output values that will be needed by other systems
# - Group related outputs together
# ============================================================================

# ----------------------------------------------------------------------------
# VPC Outputs
# ----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC created for this project"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# ----------------------------------------------------------------------------
# Subnet Outputs
# ----------------------------------------------------------------------------

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = aws_subnet.public.cidr_block
}

output "availability_zone" {
  description = "Availability zone where resources are deployed"
  value       = aws_subnet.public.availability_zone
}

# ----------------------------------------------------------------------------
# Security Group Outputs
# ----------------------------------------------------------------------------

output "security_group_id" {
  description = "ID of the web server security group"
  value       = aws_security_group.web.id
}

output "security_group_name" {
  description = "Name of the web server security group"
  value       = aws_security_group.web.name
}

# ----------------------------------------------------------------------------
# EC2 Instance Outputs
# ----------------------------------------------------------------------------

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web_server.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

output "instance_ami" {
  description = "AMI ID used for the EC2 instance"
  value       = aws_instance.web_server.ami
}

output "instance_type" {
  description = "Instance type of the EC2 instance"
  value       = aws_instance.web_server.instance_type
}

# ----------------------------------------------------------------------------
# Connection Information (Most Useful for Users)
# ----------------------------------------------------------------------------

output "web_server_url" {
  description = "URL to access the web server (HTTP)"
  value       = "http://${aws_instance.web_server.public_ip}"
}

output "ssh_connection" {
  description = "SSH connection command for the EC2 instance"
  value       = "ssh -i <your-key.pem> ec2-user@${aws_instance.web_server.public_ip}"
}

# ----------------------------------------------------------------------------
# Infrastructure Summary Output
# ----------------------------------------------------------------------------

output "infrastructure_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    project_name      = var.project_name
    environment       = var.environment
    region            = var.aws_region
    vpc_id            = aws_vpc.main.id
    subnet_id         = aws_subnet.public.id
    instance_id       = aws_instance.web_server.id
    public_ip         = aws_instance.web_server.public_ip
    web_url           = "http://${aws_instance.web_server.public_ip}"
    availability_zone = aws_subnet.public.availability_zone
  }
}

# ============================================================================
# SENSITIVE OUTPUTS
# ============================================================================
# Mark outputs as sensitive to hide them from console output
# They will still be stored in state file (which should be encrypted)

# Example: Database password output (if you had a database)
# output "database_password" {
#   description = "Password for the database"
#   value       = random_password.db_password.result
#   sensitive   = true
# }

# To view sensitive outputs: terraform output -json | jq '.database_password.value'

# ============================================================================
# ADVANCED OUTPUT PATTERNS
# ============================================================================

# ----------------------------------------------------------------------------
# PATTERN 1: Conditional outputs
# ----------------------------------------------------------------------------
# Output values based on conditions

# output "elastic_ip" {
#   description = "Elastic IP address (if created)"
#   value       = var.create_eip ? aws_eip.web_server[0].public_ip : null
# }

# ----------------------------------------------------------------------------
# PATTERN 2: Formatted outputs
# ----------------------------------------------------------------------------
# Format outputs for easy consumption

# output "instance_details" {
#   description = "Formatted instance details"
#   value = format(
#     "Instance %s (%s) is running at %s",
#     aws_instance.web_server.id,
#     var.instance_type,
#     aws_instance.web_server.public_ip
#   )
# }

# ----------------------------------------------------------------------------
# PATTERN 3: List/Map outputs
# ----------------------------------------------------------------------------
# Output collections of values

# output "all_subnet_ids" {
#   description = "List of all subnet IDs"
#   value       = [for subnet in aws_subnet.private : subnet.id]
# }

# ============================================================================
# USING OUTPUTS IN OTHER TERRAFORM PROJECTS
# ============================================================================
# Other Terraform configurations can reference these outputs via remote state:
#
# data "terraform_remote_state" "network" {
#   backend = "s3"
#   config = {
#     bucket = "my-terraform-state"
#     key    = "day6/terraform.tfstate"
#     region = "us-east-1"
#   }
# }
#
# Then use: data.terraform_remote_state.network.outputs.vpc_id
# ============================================================================

# ============================================================================
# OUTPUT COMMANDS CHEATSHEET:
# - terraform output                   # Show all outputs
# - terraform output vpc_id            # Show specific output
# - terraform output -json             # Show all in JSON format
# - terraform output -raw instance_id  # Show raw value (no quotes)
# ============================================================================
