# ============================================================================
# MAIN.TF - Modern Terraform File Organization Approach
# ============================================================================
#
# IMPORTANT NOTE ABOUT FILE ORGANIZATION:
# In this Day 6 project, we follow MODERN TERRAFORM BEST PRACTICES by
# organizing resources into separate, purpose-specific files instead of
# putting everything in main.tf.
#
# This is DIFFERENT from earlier days where everything was in main.tf.
# ============================================================================

# ============================================================================
# WHY WE DON'T USE MAIN.TF FOR ALL RESOURCES ANYMORE
# ============================================================================
#
# OLDER APPROACH (Days 1-5):
# ✗ Put all resources in main.tf
# ✗ File becomes huge and hard to navigate
# ✗ Difficult to find specific resources
# ✗ Merge conflicts in team environments
# ✗ Hard to understand project structure
#
# MODERN APPROACH (Day 6 and beyond):
# ✓ Separate files by resource category
# ✓ Each file has a clear, single purpose
# ✓ Easy to navigate and maintain
# ✓ Better for team collaboration
# ✓ Follows industry best practices
#
# ============================================================================

# ============================================================================
# FILE ORGANIZATION PATTERN FOR THIS PROJECT
# ============================================================================
#
# Core Configuration Files:
# ├── versions.tf       - Terraform and provider version constraints
# ├── providers.tf      - Provider configuration (AWS region, credentials)
# ├── variables.tf      - Input variable declarations
# ├── terraform.tfvars  - Actual variable values
# ├── locals.tf         - Local computed values
# └── data.tf           - Data source queries (AMI lookup, etc.)
#
# Resource Files (organized by type):
# ├── network.tf        - VPC, subnets, IGW, route tables
# ├── security.tf       - Security groups and network ACLs
# ├── compute.tf        - EC2 instances and related resources
# └── outputs.tf        - Output values from the configuration
#
# Optional Files (for larger projects):
# ├── backend.tf        - Remote state backend configuration
# ├── iam.tf            - IAM roles, policies, instance profiles
# ├── database.tf       - RDS, DynamoDB resources
# ├── storage.tf        - S3 buckets, EBS volumes
# └── dns.tf            - Route53 DNS records
#
# ============================================================================

# ============================================================================
# TERRAFORM FILE LOADING BEHAVIOR
# ============================================================================
#
# CRITICAL UNDERSTANDING:
# Terraform loads ALL .tf files in the current directory and treats them
# as if they were one large configuration file. The file names and order
# do NOT matter to Terraform - it builds a dependency graph automatically.
#
# LOADING PROCESS:
# 1. Reads all .tf files in alphabetical order
# 2. Merges them into a single configuration
# 3. Builds a dependency graph based on resource references
# 4. Executes in dependency order (not file order)
#
# EXAMPLE:
# Even though compute.tf comes before network.tf alphabetically,
# Terraform knows EC2 instances depend on VPC and subnets,
# so it creates the VPC and subnets FIRST, then the EC2 instance.
#
# BENEFIT:
# You can organize files however makes sense for YOUR project.
# Terraform figures out the dependencies automatically.
#
# ============================================================================

# ============================================================================
# VARIABLE LOADING PRECEDENCE
# ============================================================================
#
# Variables can be set in multiple places. Terraform uses this precedence
# (highest priority first):
#
# 1. Command-line flags:
#    terraform apply -var="instance_type=t2.small"
#
# 2. *.auto.tfvars or *.auto.tfvars.json files (alphabetical order):
#    production.auto.tfvars
#
# 3. terraform.tfvars or terraform.tfvars.json file:
#    terraform.tfvars
#
# 4. Environment variables:
#    export TF_VAR_instance_type="t2.small"
#
# 5. Default values in variables.tf:
#    variable "instance_type" { default = "t2.micro" }
#
# 6. Interactive prompt (if no default and value not provided)
#
# ============================================================================

# ============================================================================
# BEST PRACTICES FOR FILE ORGANIZATION
# ============================================================================
#
# 1. SEPARATION OF CONCERNS
#    - Keep related resources together in one file
#    - Don't mix networking and compute in the same file
#    - Example: All VPC-related resources in network.tf
#
# 2. CONSISTENT NAMING
#    - Use descriptive file names (network.tf, not net.tf)
#    - Follow team conventions
#    - Common patterns: <category>.tf (e.g., database.tf, storage.tf)
#
# 3. FILE SIZE
#    - Keep files manageable (< 500 lines)
#    - If a file gets too large, split by sub-category
#    - Example: Split network.tf into vpc.tf and subnets.tf
#
# 4. CONFIGURATION FILES ORDER
#    - Place configuration files (versions, providers, variables) before
#      resource files when viewing project
#    - Makes it easy for new team members to understand dependencies
#
# 5. DOCUMENTATION
#    - Add comments explaining WHY, not WHAT
#    - Document non-obvious dependencies
#    - Explain business logic and design decisions
#
# 6. MODULE PATTERN (Advanced)
#    - For larger projects, organize into modules
#    - Each module has its own directory with standard files
#    - Root module calls child modules
#
# ============================================================================

# ============================================================================
# WHEN TO USE MODULES VS SEPARATE FILES
# ============================================================================
#
# SEPARATE FILES (Our Day 6 approach):
# - Good for: Single-environment, learning, small projects
# - Pros: Simple, easy to understand, all in one place
# - Cons: Less reusable, harder to manage multiple environments
# - Use when: You have one environment or are learning
#
# MODULES (Production approach):
# - Good for: Multi-environment, reusable components, large projects
# - Pros: Highly reusable, testable, composable
# - Cons: More complex, steeper learning curve
# - Use when: Multiple environments (dev, staging, prod)
#
# EXAMPLE MODULE STRUCTURE:
# .
# ├── modules/
# │   ├── vpc/
# │   │   ├── main.tf
# │   │   ├── variables.tf
# │   │   └── outputs.tf
# │   └── ec2/
# │       ├── main.tf
# │       ├── variables.tf
# │       └── outputs.tf
# └── environments/
#     ├── dev/
#     │   └── main.tf (calls modules)
#     └── prod/
#         └── main.tf (calls modules)
#
# ============================================================================

# ============================================================================
# RESOURCES FOR THIS PROJECT ARE LOCATED IN:
# ============================================================================
#
# Network Resources:    network.tf
# Security Resources:   security.tf
# Compute Resources:    compute.tf
# Output Values:        outputs.tf
#
# Configuration:
# - Version Constraints: versions.tf
# - Provider Setup:      providers.tf
# - Variable Definitions: variables.tf
# - Variable Values:     terraform.tfvars
# - Local Values:        locals.tf
# - Data Sources:        data.tf
#
# ============================================================================

# ============================================================================
# NEXT STEPS TO DEPLOY THIS INFRASTRUCTURE
# ============================================================================
#
# 1. Initialize Terraform (download providers):
#    terraform init
#
# 2. Format code (optional but recommended):
#    terraform fmt
#
# 3. Validate configuration:
#    terraform validate
#
# 4. Preview changes:
#    terraform plan
#
# 5. Apply configuration:
#    terraform apply
#
# 6. View outputs:
#    terraform output
#
# 7. Access web server:
#    Open the URL from 'terraform output web_server_url'
#
# 8. Destroy when done (to avoid charges):
#    terraform destroy
#
# ============================================================================

# This file intentionally left mostly empty to demonstrate that main.tf
# doesn't need to contain resources when using modern file organization.
