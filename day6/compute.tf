# ============================================================================
# COMPUTE.TF - EC2 Instance Configuration
# ============================================================================
#
# PURPOSE:
# Defines EC2 compute resources including instances and associated resources.
#
# RESOURCE DEPENDENCIES:
# EC2 depends on: VPC, Subnet, Security Group, AMI (from data source)
# Terraform automatically determines the correct creation order.
#
# BEST PRACTICES:
# - Use data sources for AMI lookup (don't hardcode AMI IDs)
# - Tag instances for cost tracking and identification
# - Use user_data for initial instance configuration
# - Enable detailed monitoring only when needed (costs extra)
# ============================================================================

# ----------------------------------------------------------------------------
# EC2 Instance - Web Server
# ----------------------------------------------------------------------------

resource "aws_instance" "web_server" {
  # AMI from data source - automatically uses latest Amazon Linux 2
  ami = data.aws_ami.amazon_linux.id

  # Instance type from variable - default is t2.micro (free tier)
  instance_type = var.instance_type

  # Network configuration
  subnet_id = aws_subnet.public.id # Launch in public subnet

  # Security group attachment
  vpc_security_group_ids = [aws_security_group.web.id]

  # Associate public IP address for internet access
  # This is redundant if subnet has map_public_ip_on_launch = true
  # But explicit is better than implicit for clarity
  associate_public_ip_address = true

  # Root volume configuration
  root_block_device {
    volume_size           = var.root_volume_size # Size in GB
    volume_type           = "gp3"                # General Purpose SSD v3 (faster and cheaper than gp2)
    delete_on_termination = true                 # Delete volume when instance terminates
    encrypted             = true                 # Enable encryption at rest

    # Optional: Add tags to the volume
    tags = {
      Name = "${local.ec2_name}-root-volume"
    }
  }

  # User data script - runs on first boot
  # This script installs and starts Apache web server
  user_data = local.user_data

  # Enable detailed monitoring (costs extra)
  monitoring = var.enable_monitoring

  # Optional: SSH Key for access
  # Uncomment and set key_name variable if you want SSH access
  # key_name = var.key_name

  # Optional: IAM instance profile for AWS API access
  # iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Optional: Disable source/destination check (needed for NAT instances)
  # source_dest_check = false

  # Metadata options for enhanced security (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"  # Enable metadata service
    http_tokens                 = "required" # Require IMDSv2 (more secure)
    http_put_response_hop_limit = 1          # Limit metadata service access
    instance_metadata_tags      = "enabled"  # Enable instance tags in metadata
  }

  # Tags for identification and cost tracking
  tags = merge(
    local.common_tags,
    {
      Name = local.ec2_name
      Type = "EC2 Instance"
      Role = "Web Server"
    }
  )

  # Lifecycle management
  lifecycle {
    # Prevent accidental instance termination
    # Uncomment for production instances
    # prevent_destroy = true

    # Create new instance before destroying old one during updates
    # Useful for zero-downtime deployments
    # create_before_destroy = true

    # Ignore changes to user_data after initial creation
    # Prevents instance recreation when user_data changes
    # ignore_changes = [user_data]
  }
}

# ============================================================================
# INSTANCE STATES:
# - pending: Instance is launching
# - running: Instance is running
# - stopping: Instance is shutting down
# - stopped: Instance is stopped (not charged for compute)
# - terminating: Instance is being deleted
# - terminated: Instance has been deleted
# ============================================================================

# ============================================================================
# USER DATA NOTES:
# - Runs only ONCE on first boot
# - Runs as root user
# - Logs available at: /var/log/cloud-init-output.log
# - To update: Create new AMI or use configuration management tools
# - Character limit: 16 KB for raw user data
# ============================================================================

# ============================================================================
# OPTIONAL: Elastic IP (Static Public IP)
# ============================================================================
# Uncomment to assign a static public IP that persists across instance restarts

# resource "aws_eip" "web_server" {
#   domain   = "vpc"
#   instance = aws_instance.web_server.id
#
#   tags = merge(
#     local.common_tags,
#     {
#       Name = "${local.ec2_name}-eip"
#       Type = "Elastic IP"
#     }
#   )
#
#   # Ensure EIP is created after IGW
#   depends_on = [aws_internet_gateway.main]
# }

# ELASTIC IP BENEFITS:
# - Static IP that doesn't change when instance stops/starts
# - Can be reassigned to different instances
# - Costs money when not attached to a running instance
# - Useful for DNS records and whitelisting

# ============================================================================
# OPTIONAL: Additional EBS Volume
# ============================================================================
# Uncomment to attach an additional data volume

# resource "aws_ebs_volume" "data" {
#   availability_zone = local.az
#   size              = 20  # Size in GB
#   type              = "gp3"
#   encrypted         = true
#
#   tags = merge(
#     local.common_tags,
#     {
#       Name = "${local.ec2_name}-data-volume"
#       Type = "EBS Volume"
#     }
#   )
# }

# resource "aws_volume_attachment" "data" {
#   device_name = "/dev/sdf"
#   volume_id   = aws_ebs_volume.data.id
#   instance_id = aws_instance.web_server.id
# }

# ============================================================================
# DEBUGGING EC2 ISSUES:
# 1. Check instance state: AWS Console -> EC2 -> Instances
# 2. Review system log: Actions -> Monitor and troubleshoot -> Get system log
# 3. Check user_data execution: SSH and view /var/log/cloud-init-output.log
# 4. Verify security group allows required ports
# 5. Ensure subnet has internet gateway route (for public access)
# 6. Check if instance has public IP assigned
# ============================================================================
