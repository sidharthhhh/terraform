# ============================================================================
# PROVIDERS.TF - Provider Configuration
# ============================================================================
#
# PURPOSE:
# Configures how Terraform communicates with cloud providers (AWS in this case).
# This is where you set region, credentials, and provider-specific settings.
#
# LOADING ORDER:
# Loaded during 'terraform init' and every 'terraform plan/apply'.
# Terraform uses this to establish connections to AWS APIs.
#
# AUTHENTICATION OPTIONS:
# 1. Environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
# 2. AWS credentials file: ~/.aws/credentials
# 3. IAM role (when running on EC2 or in CI/CD)
# 4. Explicit keys (NOT RECOMMENDED for security reasons)
#
# BEST PRACTICES:
# - Never hardcode credentials in this file
# - Use variables for region to support multiple environments
# - Add default tags for resource organization and cost tracking
# ============================================================================

provider "aws" {
  # AWS Region where resources will be created
  # Using a variable allows us to deploy to different regions easily
  region = var.aws_region

  # Default tags applied to ALL resources created by this provider
  # This is excellent for:
  # - Cost allocation and tracking
  # - Resource organization
  # - Identifying resources created by Terraform
  # - Environment identification (dev, staging, prod)
  default_tags {
    tags = {
      Project     = "Terraform-Day6" # Project identifier
      ManagedBy   = "Terraform"      # Indicates Terraform manages this
      Environment = var.environment  # Environment (dev, staging, prod)
      Owner       = "Sidharth"       # Resource owner
      CreatedDate = "2026-01-07"     # Creation date for tracking
    }
  }

  # OPTIONAL: Additional provider configurations
  # Uncomment as needed for your use case

  # Skip metadata API check (useful for local development)
  # skip_metadata_api_check = true

  # Skip requesting account ID (speeds up plan/apply)
  # skip_requesting_account_id = true

  # Assume role for cross-account access
  # assume_role {
  #   role_arn = "arn:aws:iam::ACCOUNT_ID:role/TerraformRole"
  # }
}

# ============================================================================
# MULTIPLE PROVIDER CONFIGURATIONS (Advanced Pattern):
# You can define multiple configurations of the same provider using aliases.
# Useful for multi-region deployments or cross-account scenarios.
# 
# Example:
# provider "aws" {
#   alias  = "us_west"
#   region = "us-west-2"
# }
#
# Then reference it in resources:
# resource "aws_instance" "west_server" {
#   provider = aws.us_west
#   ...
# }
# ============================================================================
