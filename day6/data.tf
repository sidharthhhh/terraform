# ============================================================================
# DATA.TF - Data Sources (External Data Queries)
# ============================================================================
#
# PURPOSE:
# Data sources allow Terraform to fetch information from external systems.
# They are READ-ONLY and don't create or modify infrastructure.
#
# COMMON USE CASES:
# 1. Find latest AMI IDs (so you don't hardcode old AMI IDs)
# 2. Get availability zones in a region
# 3. Fetch existing VPC or subnet information
# 4. Look up AWS account information
# 5. Read remote state from other Terraform projects
#
# LOADING ORDER:
# Data sources are queried during the planning phase.
# They are refreshed every time you run terraform plan/apply.
#
# NAMING CONVENTION:
# data.<type>.<name>.<attribute>
# Example: data.aws_ami.amazon_linux.id
#
# BEST PRACTICES:
# - Use data sources for information that changes over time (like AMIs)
# - Keep data lookups in this file for organization
# - Add filters to ensure you get exactly what you expect
# - Use most_recent = true for AMIs to get latest versions
# ============================================================================

# ----------------------------------------------------------------------------
# Get Available Availability Zones
# ----------------------------------------------------------------------------

# This data source fetches all available AZs in the current region
# Useful for dynamic subnet placement without hardcoding AZ names
data "aws_availability_zones" "available" {
  # Only include AZs that are currently available
  state = "available"

  # Optional: Exclude local zones and wavelength zones
  # Uncomment if you only want standard AZs
  # filter {
  #   name   = "opt-in-status"
  #   values = ["opt-in-not-required"]
  # }
}

# USAGE EXAMPLE:
# availability_zone = data.aws_availability_zones.available.names[0]
# This gets the first available AZ in the region

# ----------------------------------------------------------------------------
# Get Latest Amazon Linux 2 AMI
# ----------------------------------------------------------------------------

# This data source dynamically finds the latest Amazon Linux 2 AMI
# Benefits:
# 1. Always uses the most recent AMI with latest security patches
# 2. No need to update AMI IDs when AWS releases new versions
# 3. Works across different regions (AMI IDs are region-specific)
data "aws_ami" "amazon_linux" {
  # Get the most recently created AMI that matches our filters
  most_recent = true

  # Filter criteria to find the right AMI
  filter {
    name   = "name"
    values = [var.ami_filter_name] # e.g., "amzn2-ami-hvm-*-x86_64-gp2"
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"] # Hardware Virtual Machine (standard for modern EC2)
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"] # EBS-backed instances (most common)
  }

  filter {
    name   = "architecture"
    values = ["x86_64"] # 64-bit architecture
  }

  # Owner of the AMI - "amazon" means official AWS AMIs
  # Using variable allows flexibility (could use different AMI sources)
  owners = [var.ami_owner]

  # Optional: Additional filters for specific AMI characteristics
  # filter {
  #   name   = "state"
  #   values = ["available"]
  # }
}

# USAGE EXAMPLE:
# ami = data.aws_ami.amazon_linux.id
# This gives you the AMI ID of the latest Amazon Linux 2 image

# ----------------------------------------------------------------------------
# Get Current AWS Account Information
# ----------------------------------------------------------------------------

# Fetches information about the current AWS account
# Useful for constructing ARNs, setting up cross-account access, etc.
data "aws_caller_identity" "current" {}

# AVAILABLE ATTRIBUTES:
# - data.aws_caller_identity.current.account_id
# - data.aws_caller_identity.current.arn
# - data.aws_caller_identity.current.user_id

# ----------------------------------------------------------------------------
# Get Current AWS Region Information
# ----------------------------------------------------------------------------

# Fetches detailed information about the current region
# Provides region name, description, and endpoint
data "aws_region" "current" {}

# AVAILABLE ATTRIBUTES:
# - data.aws_region.current.name (e.g., "us-east-1")
# - data.aws_region.current.description (e.g., "US East (N. Virginia)")
# - data.aws_region.current.endpoint (e.g., "ec2.us-east-1.amazonaws.com")

# ============================================================================
# ADVANCED DATA SOURCE PATTERNS:
# ============================================================================

# ----------------------------------------------------------------------------
# PATTERN 1: Query existing VPC (for multi-tier projects)
# ----------------------------------------------------------------------------
# data "aws_vpc" "existing" {
#   # Find VPC by tag
#   filter {
#     name   = "tag:Name"
#     values = ["my-existing-vpc"]
#   }
# }
# 
# # Then reference it:
# # vpc_id = data.aws_vpc.existing.id

# ----------------------------------------------------------------------------
# PATTERN 2: Find specific subnet
# ----------------------------------------------------------------------------
# data "aws_subnet" "selected" {
#   filter {
#     name   = "tag:Name"
#     values = ["my-public-subnet"]
#   }
# }

# ----------------------------------------------------------------------------
# PATTERN 3: Get remote state from another Terraform project
# ----------------------------------------------------------------------------
# data "terraform_remote_state" "network" {
#   backend = "s3"
#   config = {
#     bucket = "my-terraform-state"
#     key    = "network/terraform.tfstate"
#     region = "us-east-1"
#   }
# }
# 
# # Reference outputs from other project:
# # vpc_id = data.terraform_remote_state.network.outputs.vpc_id

# ----------------------------------------------------------------------------
# PATTERN 4: Get AWS-managed prefix list (for S3, CloudFront, etc.)
# ----------------------------------------------------------------------------
# data "aws_ec2_managed_prefix_list" "s3" {
#   filter {
#     name   = "prefix-list-name"
#     values = ["com.amazonaws.${var.aws_region}.s3"]
#   }
# }

# ============================================================================
# DATA SOURCES VS RESOURCES:
# - DATA SOURCES: Query existing infrastructure (read-only)
# - RESOURCES: Create/modify infrastructure (read-write)
#
# DATA SOURCE REFRESH:
# Data sources are refreshed during every plan/apply.
# Use -refresh=false to skip refresh if data is expensive to query.
# ============================================================================
