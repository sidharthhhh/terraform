terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Example 1: Launch Template with create_before_destroy
# This is commonly needed to avoid downtime when updating launch templates
resource "aws_launch_template" "app" {
  name_prefix   = "app-server-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Hello from version ${var.app_version}" > /var/www/html/index.html
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              EOF
  )

  # create_before_destroy is CRITICAL for launch templates
  # Auto Scaling Groups reference launch templates by ID
  # If you destroy first, ASG loses its template reference
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name      = "App Server Template"
    Version   = var.app_version
    ManagedBy = "Terraform"
  }
}

# Example 2: Security Group with create_before_destroy
# Prevents connection interruptions when updating SG rules
resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # If name changes, create new SG before destroying old one
  # This prevents instances from losing their security group
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name      = "Web Security Group"
    ManagedBy = "Terraform"
  }
}

# VPC for the example
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "Main VPC"
    ManagedBy = "Terraform"
  }
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "Public Subnet"
    ManagedBy = "Terraform"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "Main IGW"
    ManagedBy = "Terraform"
  }
}

# Example 3: ALB Target Group with create_before_destroy
# Critical for zero-downtime deployments
resource "aws_lb_target_group" "app" {
  name_prefix = "app-"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  # When updating target group, create new one first
  # This allows traffic to continue flowing to old group
  # until new group is ready
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name      = "App Target Group"
    ManagedBy = "Terraform"
  }
}

# Variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "v1.0"
}

# Data source for latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
