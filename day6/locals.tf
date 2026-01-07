# ============================================================================
# LOCALS.TF - Local Values (Computed and Derived Values)
# ============================================================================
#
# PURPOSE:
# Defines local values that are computed, reused, or derived from variables.
# Locals help reduce repetition and make complex expressions more readable.
#
# DIFFERENCE FROM VARIABLES:
# - Variables: Input from external sources (CLI, tfvars, environment)
# - Locals: Computed within Terraform configuration, not settable externally
#
# WHEN TO USE LOCALS:
# 1. To avoid repeating the same expression multiple times
# 2. To give a meaningful name to a complex expression
# 3. To combine multiple variable values
# 4. To define common tags or naming conventions
#
# LOADING ORDER:
# Locals are evaluated during plan/apply phase.
# They can reference variables, resources, and other locals.
#
# BEST PRACTICES:
# - Use locals for DRY (Don't Repeat Yourself) principle
# - Name locals clearly to indicate their purpose
# - Group related locals together
# - Document complex expressions
# ============================================================================

locals {
  # --------------------------------------------------------------------------
  # Naming Convention Locals
  # --------------------------------------------------------------------------

  # Common prefix for all resource names
  # Format: project-environment (e.g., terraform-day6-dev)
  # This ensures consistent, identifiable resource names across AWS
  name_prefix = "${var.project_name}-${var.environment}"

  # Resource-specific names using the common prefix
  # This makes it easy to identify resources and their purpose
  vpc_name            = "${local.name_prefix}-vpc"
  public_subnet_name  = "${local.name_prefix}-public-subnet"
  private_subnet_name = "${local.name_prefix}-private-subnet"
  igw_name            = "${local.name_prefix}-igw"
  public_rt_name      = "${local.name_prefix}-public-rt"
  sg_web_name         = "${local.name_prefix}-web-sg"
  ec2_name            = "${local.name_prefix}-web-server"

  # --------------------------------------------------------------------------
  # Common Tags
  # --------------------------------------------------------------------------

  # Tags applied to resources in addition to provider default_tags
  # Using locals allows us to reference these tags in multiple resources
  common_tags = {
    Name       = local.name_prefix
    Purpose    = "Learning Terraform file organization"
    Day        = "Day 6"
    Terraform  = "true"
    CostCenter = "Engineering"
  }

  # --------------------------------------------------------------------------
  # Computed Values
  # --------------------------------------------------------------------------

  # Current timestamp for unique identifiers (if needed)
  # Note: Be careful with timestamps - they change on every apply!
  # timestamp = formatdate("YYYY-MM-DD-hhmm", timestamp())

  # Availability Zone selection
  # If not specified in variables, use the first available AZ in the region
  # This demonstrates conditional logic in locals
  az = var.availability_zone != "" ? var.availability_zone : data.aws_availability_zones.available.names[0]

  # --------------------------------------------------------------------------
  # Security Group Rules (Advanced Pattern)
  # --------------------------------------------------------------------------

  # Conditional SSH rule - only create if SSH is enabled
  # This pattern makes it easy to toggle features on/off
  ssh_ingress_rules = var.enable_ssh ? [{
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }] : []

  # Conditional HTTP rule - only create if HTTP is enabled
  http_ingress_rules = var.enable_http ? [{
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }] : []

  # Combined ingress rules for security group
  # This allows dynamic rule creation based on variables
  all_ingress_rules = concat(
    local.ssh_ingress_rules,
    local.http_ingress_rules
  )

  # --------------------------------------------------------------------------
  # User Data Script
  # --------------------------------------------------------------------------

  # EC2 user data script for Apache web server installation
  # Using a local makes it easier to manage and update the script
  # This script runs once when the instance first boots
  user_data = <<-EOF
    #!/bin/bash
    # Update system packages
    yum update -y
    
    # Install Apache web server
    yum install -y httpd
    
    # Start Apache service
    systemctl start httpd
    
    # Enable Apache to start on boot
    systemctl enable httpd
    
    # Create a simple HTML page with instance metadata
    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
    <head>
      <title>Terraform Day 6 - Success!</title>
      <style>
        body { 
          font-family: Arial, sans-serif; 
          text-align: center; 
          padding: 50px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
        }
        .container {
          background: rgba(255,255,255,0.1);
          padding: 30px;
          border-radius: 10px;
          backdrop-filter: blur(10px);
        }
        h1 { font-size: 3em; margin: 0; }
        p { font-size: 1.2em; }
        .info { 
          background: rgba(0,0,0,0.2); 
          padding: 15px; 
          margin: 20px 0;
          border-radius: 5px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 Success!</h1>
        <p>Your Terraform-managed EC2 instance is running!</p>
        <div class="info">
          <p><strong>Project:</strong> ${var.project_name}</p>
          <p><strong>Environment:</strong> ${var.environment}</p>
          <p><strong>Managed By:</strong> Terraform</p>
          <p><strong>Instance Type:</strong> ${var.instance_type}</p>
        </div>
        <p>This page was automatically configured using Terraform user_data</p>
      </div>
    </body>
    </html>
    HTML
  EOF
}

# ============================================================================
# USING LOCALS IN OTHER FILES:
# Reference locals using: local.local_name (note: "local" not "locals")
# Example: name = local.vpc_name
#
# LOCALS VS VARIABLES - QUICK REFERENCE:
# Use VARIABLES when: Value comes from outside (user input, tfvars, CLI)
# Use LOCALS when: Value is computed/derived from other values
#
# TERRAFORM EXPRESSION SYNTAX:
# - String interpolation: "${var.name}-${var.env}"
# - Conditional: condition ? true_val : false_val
# - Functions: concat(), formatdate(), cidrsubnet(), etc.
# - For loops: [for item in list : transform(item)]
# ============================================================================
