# ============================================================================
# SECURITY.TF - Security Groups and Network Access Control
# ============================================================================
#
# PURPOSE:
# Defines security groups that act as virtual firewalls for EC2 instances.
# Security groups control inbound and outbound traffic at the instance level.
#
# SECURITY GROUPS VS NACLs:
# - Security Groups: Instance level, Stateful, Allow rules only
# - NACLs: Subnet level, Stateless, Allow and Deny rules
#
# BEST PRACTICES:
# - Principle of least privilege (only open ports you need)
# - Never use 0.0.0.0/0 for SSH in production
# - Use descriptive names and descriptions
# ============================================================================

# ----------------------------------------------------------------------------
# Web Server Security Group
# ----------------------------------------------------------------------------

resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Security group for web server - allows HTTP, HTTPS, and SSH"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name    = local.sg_web_name
      Type    = "Security Group"
      Purpose = "Web Server Access"
    }
  )
}

# ----------------------------------------------------------------------------
# Ingress Rules
# ----------------------------------------------------------------------------

# SSH access (Port 22)
resource "aws_security_group_rule" "ssh" {
  count             = var.enable_ssh ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidr
  description       = "Allow SSH access for remote management"
  security_group_id = aws_security_group.web.id
}

# HTTP access (Port 80)
resource "aws_security_group_rule" "http" {
  count             = var.enable_http ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidr
  description       = "Allow HTTP web traffic"
  security_group_id = aws_security_group.web.id
}

# HTTPS access (Port 443)
resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_https_cidr
  description       = "Allow HTTPS secure web traffic"
  security_group_id = aws_security_group.web.id
}

# ----------------------------------------------------------------------------
# Egress Rules
# ----------------------------------------------------------------------------

# Allow all outbound traffic
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # All protocols
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.web.id
}

# ============================================================================
# SECURITY NOTES:
# - SSH from 0.0.0.0/0 is insecure - restrict to your IP in production
# - Security groups are STATEFUL (return traffic is automatic)
# - Use VPC Flow Logs to debug connectivity issues
# ============================================================================
