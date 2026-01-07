# ============================================================================
# NETWORK.TF - VPC and Networking Resources
# ============================================================================
#
# PURPOSE:
# Defines all networking infrastructure including VPC, subnets, internet
# gateway, route tables, and their associations.
#
# NETWORK ARCHITECTURE:
# VPC (10.0.0.0/16)
#   ├── Public Subnet (10.0.1.0/24) - Has internet access via IGW
#   │   ├── Internet Gateway (IGW)
#   │   └── Route Table (0.0.0.0/0 -> IGW)
#   └── [Future] Private Subnet (10.0.2.0/24) - No direct internet access
#
# RESOURCE DEPENDENCIES (Terraform determines order automatically):
# 1. VPC created first (no dependencies)
# 2. Subnets depend on VPC
# 3. Internet Gateway depends on VPC
# 4. Route Table depends on VPC and IGW
# 5. Route Table Association depends on Subnet and Route Table
#
# BEST PRACTICES:
# - Use descriptive names and tags for all resources
# - Enable DNS support for VPC (required for many AWS services)
# - Create separate route tables for public and private subnets
# - Document CIDR allocation strategy
# ============================================================================

# ----------------------------------------------------------------------------
# VPC (Virtual Private Cloud)
# ----------------------------------------------------------------------------

# VPC is the foundation of AWS networking
# It's a logically isolated virtual network where you launch AWS resources
resource "aws_vpc" "main" {
  # CIDR block defines the IP address range for the entire VPC
  # 10.0.0.0/16 provides 65,536 IP addresses (10.0.0.0 to 10.0.255.255)
  cidr_block = var.vpc_cidr

  # Enable DNS hostnames - Allows EC2 instances to get public DNS names
  # Required for many AWS services and recommended for best practices
  enable_dns_hostnames = true

  # Enable DNS support - Allows DNS resolution within the VPC
  # This lets resources resolve AWS service endpoints and each other
  enable_dns_support = true

  # Optional: Enable IPv6 (uncomment if needed)
  # assign_generated_ipv6_cidr_block = true

  # Tags for identification and organization
  tags = merge(
    local.common_tags,
    {
      Name = local.vpc_name
      Type = "VPC"
    }
  )
}

# WHY DNS IS IMPORTANT:
# - DNS hostnames: ec2-XX-XX-XX-XX.compute-1.amazonaws.com
# - DNS support: Resolves S3, DynamoDB, and other AWS service endpoints
# - Without these, instances can't resolve AWS service names

# ----------------------------------------------------------------------------
# Public Subnet
# ----------------------------------------------------------------------------

# Public subnet has a route to the Internet Gateway
# Resources here can have public IPs and access the internet
resource "aws_subnet" "public" {
  # Reference to parent VPC - Creates implicit dependency
  vpc_id = aws_vpc.main.id

  # Subnet CIDR must be within VPC CIDR range
  # 10.0.1.0/24 provides 256 IPs (251 usable after AWS reserves 5)
  cidr_block = var.public_subnet_cidr

  # Availability Zone placement
  # Using local.az allows for automatic or manual AZ selection
  availability_zone = local.az

  # Auto-assign public IPv4 addresses to instances launched in this subnet
  # Essential for instances that need internet access
  map_public_ip_on_launch = true

  # Optional: IPv6 configuration
  # assign_ipv6_address_on_creation = true
  # ipv6_cidr_block = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1)

  tags = merge(
    local.common_tags,
    {
      Name = local.public_subnet_name
      Type = "Public Subnet"
      Tier = "Public"
    }
  )
}

# AWS RESERVES 5 IPs PER SUBNET:
# For 10.0.1.0/24:
# - 10.0.1.0: Network address
# - 10.0.1.1: VPC router
# - 10.0.1.2: DNS server (Amazon-provided DNS)
# - 10.0.1.3: Reserved for future use
# - 10.0.1.255: Network broadcast address
# Usable IPs: 10.0.1.4 to 10.0.1.254 (251 addresses)

# ----------------------------------------------------------------------------
# Internet Gateway (IGW)
# ----------------------------------------------------------------------------

# Internet Gateway provides internet connectivity for public subnets
# This is the bridge between your VPC and the internet
resource "aws_internet_gateway" "main" {
  # Attach to VPC - Creates implicit dependency on VPC
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = local.igw_name
      Type = "Internet Gateway"
    }
  )
}

# IGW CHARACTERISTICS:
# - Horizontally scaled, redundant, and highly available by default
# - No availability zone dependency
# - Supports both IPv4 and IPv6
# - No bandwidth constraints imposed by AWS

# ----------------------------------------------------------------------------
# Route Table for Public Subnet
# ----------------------------------------------------------------------------

# Route table defines where network traffic is directed
# Public route table routes internet traffic to the IGW
resource "aws_route_table" "public" {
  # Associate with VPC
  vpc_id = aws_vpc.main.id

  # Default route to Internet Gateway
  # 0.0.0.0/0 means "all IPv4 traffic" that doesn't match other routes
  route {
    cidr_block = "0.0.0.0/0"                  # Destination: Any internet address
    gateway_id = aws_internet_gateway.main.id # Target: Internet Gateway
  }

  # Optional: IPv6 route to Internet Gateway
  # route {
  #   ipv6_cidr_block = "::/0"
  #   gateway_id      = aws_internet_gateway.main.id
  # }

  tags = merge(
    local.common_tags,
    {
      Name = local.public_rt_name
      Type = "Public Route Table"
    }
  )
}

# HOW ROUTING WORKS:
# 1. Instance sends packet to destination IP
# 2. VPC router checks route table for matching route
# 3. Most specific route wins (longest prefix match)
# 4. Local VPC routes are implicit (can't be deleted)
# 5. 0.0.0.0/0 is the default route (least specific)
# 
# Example routing decision:
# - Destination 10.0.1.50 -> Local VPC route (stays in VPC)
# - Destination 8.8.8.8 -> 0.0.0.0/0 route (goes to IGW)

# ----------------------------------------------------------------------------
# Route Table Association
# ----------------------------------------------------------------------------

# Associates the public route table with the public subnet
# Without this, the subnet uses the VPC's main route table
resource "aws_route_table_association" "public" {
  # Subnet to associate
  subnet_id = aws_subnet.public.id

  # Route table to use
  route_table_id = aws_route_table.public.id
}

# WHY ASSOCIATIONS MATTER:
# - Each subnet must be associated with exactly one route table
# - If not explicitly associated, uses the VPC's main route table
# - Allows different subnets to have different routing rules
# - Public subnets route to IGW, private subnets might route to NAT

# ============================================================================
# OPTIONAL: Private Subnet Configuration (for advanced architectures)
# ============================================================================

# Uncomment below to create a private subnet for databases, app servers, etc.

# resource "aws_subnet" "private" {
#   count             = var.create_private_subnet ? 1 : 0
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = var.private_subnet_cidr
#   availability_zone = local.az
#   
#   # DO NOT auto-assign public IPs in private subnets
#   map_public_ip_on_launch = false
#   
#   tags = merge(
#     local.common_tags,
#     {
#       Name = local.private_subnet_name
#       Type = "Private Subnet"
#       Tier = "Private"
#     }
#   )
# }

# Private subnets typically:
# - Don't have public IPs
# - Route internet traffic through NAT Gateway (costs money)
# - Host databases, app servers, and sensitive workloads
# - Can still access internet for updates via NAT

# ============================================================================
# NETWORK DEBUGGING TIPS:
# ============================================================================
# 1. Check route tables: AWS Console -> VPC -> Route Tables
# 2. Verify subnet associations: Ensure subnet uses correct route table
# 3. Check Security Groups: Allow outbound traffic
# 4. Check NACLs: Default allows all, custom rules may block
# 5. IGW attachment: Ensure IGW is attached to VPC
# 6. Public IP: Ensure instance has public IP for internet access
# ============================================================================
