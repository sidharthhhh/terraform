# ============================================================================
# VERSIONS.TF - Terraform and Provider Version Constraints
# ============================================================================
# 
# PURPOSE:
# This file defines the minimum required versions for Terraform and providers.
# It ensures all team members use compatible versions, preventing compatibility issues.
#
# LOADING ORDER:
# Terraform reads this file during 'terraform init' to:
# 1. Verify the installed Terraform version meets requirements
# 2. Download the correct provider versions
# 3. Lock versions in .terraform.lock.hcl for consistency
#
# BEST PRACTICES:
# - Always specify minimum versions to ensure features are available
# - Use ~> for minor version constraints (allows patch updates)
# - Keep this file at the root of your Terraform project
# ============================================================================

terraform {
  # Minimum Terraform version required
  # The ~> operator means "allow only rightmost version component to increment"
  # Example: ~> 1.0 allows 1.1, 1.2, etc. but not 2.0
  required_version = "~> 1.0"

  # Required provider configurations
  # Each provider must specify source and version constraints
  required_providers {
    # AWS Provider - Used for all AWS resource management
    aws = {
      source  = "hashicorp/aws" # Official HashiCorp AWS provider
      version = "~> 5.0"        # Allow 5.x versions (5.0, 5.1, 5.2, etc.)
    }
  }

  # OPTIONAL: Backend configuration for remote state storage
  # Uncomment and configure for team collaboration
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "day6/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

# ============================================================================
# FILE ORGANIZATION NOTE:
# Some teams combine versions.tf and providers.tf into one file.
# We keep them separate for clarity:
# - versions.tf = Version constraints (what versions to use)
# - providers.tf = Provider configuration (how to configure providers)
# ============================================================================
