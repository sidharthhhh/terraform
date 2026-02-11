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

# Sample data: Application servers configuration
variable "servers" {
  description = "Map of server configurations"
  type = map(object({
    instance_type = string
    environment   = string
    team          = string
    public        = bool
    volume_size   = number
  }))
  default = {
    "web-1" = {
      instance_type = "t2.micro"
      environment   = "production"
      team          = "platform"
      public        = true
      volume_size   = 30
    }
    "web-2" = {
      instance_type = "t2.micro"
      environment   = "production"
      team          = "platform"
      public        = true
      volume_size   = 30
    }
    "api-1" = {
      instance_type = "t2.small"
      environment   = "production"
      team          = "backend"
      public        = false
      volume_size   = 50
    }
    "db-1" = {
      instance_type = "t2.medium"
      environment   = "production"
      team          = "database"
      public        = false
      volume_size   = 100
    }
    "test-1" = {
      instance_type = "t2.micro"
      environment   = "staging"
      team          = "qa"
      public        = true
      volume_size   = 20
    }
    "dev-1" = {
      instance_type = "t2.nano"
      environment   = "development"
      team          = "developers"
      public        = true
      volume_size   = 10
    }
  }
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "Main VPC"
    ManagedBy = "Terraform"
  }
}

# Create subnets
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
    Type = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private Subnet"
    Type = "private"
  }
}

# Create EC2 instances
resource "aws_instance" "servers" {
  for_each = var.servers

  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  subnet_id     = each.value.public ? aws_subnet.public.id : aws_subnet.private.id

  root_block_device {
    volume_size = each.value.volume_size
    volume_type = "gp3"
  }

  tags = {
    Name        = each.key
    Environment = each.value.environment
    Team        = each.value.team
    Public      = tostring(each.value.public)
    ManagedBy   = "Terraform"
  }
}

# Create S3 buckets for different teams
variable "team_buckets" {
  description = "S3 buckets for different teams"
  type = map(object({
    versioning = bool
    encryption = bool
    tags       = map(string)
  }))
  default = {
    "platform-assets" = {
      versioning = true
      encryption = true
      tags = {
        Team    = "platform"
        Purpose = "static-assets"
      }
    }
    "backend-data" = {
      versioning = true
      encryption = true
      tags = {
        Team    = "backend"
        Purpose = "application-data"
      }
    }
    "database-backups" = {
      versioning = true
      encryption = true
      tags = {
        Team    = "database"
        Purpose = "backups"
      }
    }
    "qa-reports" = {
      versioning = false
      encryption = false
      tags = {
        Team    = "qa"
        Purpose = "test-reports"
      }
    }
  }
}

resource "aws_s3_bucket" "team_buckets" {
  for_each = var.team_buckets

  bucket = "${each.key}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    each.value.tags,
    {
      Name      = each.key
      ManagedBy = "Terraform"
    }
  )
}

# Enable versioning where configured
resource "aws_s3_bucket_versioning" "team_buckets" {
  for_each = {
    for k, v in var.team_buckets : k => v
    if v.versioning
  }

  bucket = aws_s3_bucket.team_buckets[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

# IAM users with different roles
variable "iam_users" {
  description = "IAM users with roles"
  type = map(object({
    role        = string
    environment = string
    active      = bool
  }))
  default = {
    "alice" = {
      role        = "admin"
      environment = "production"
      active      = true
    }
    "bob" = {
      role        = "developer"
      environment = "staging"
      active      = true
    }
    "charlie" = {
      role        = "developer"
      environment = "development"
      active      = true
    }
    "david" = {
      role        = "viewer"
      environment = "production"
      active      = false
    }
    "eve" = {
      role        = "admin"
      environment = "production"
      active      = true
    }
  }
}

resource "aws_iam_user" "users" {
  for_each = {
    for k, v in var.iam_users : k => v
    if v.active
  }

  name = each.key

  tags = {
    Role        = each.value.role
    Environment = each.value.environment
    ManagedBy   = "Terraform"
  }
}

# Data sources
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_caller_identity" "current" {}
