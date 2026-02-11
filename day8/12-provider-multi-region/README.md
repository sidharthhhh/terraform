# Provider Meta-Argument: Multi-Region Example

## 📚 What This Demonstrates
- Using multiple provider configurations with aliases
- Deploying resources across multiple AWS regions
- Multi-region disaster recovery setup
- Global application architecture
- Cross-region resource management

## 🎯 What is the Provider Meta-Argument?

The `provider` meta-argument lets you specify which provider configuration a resource should use, enabling multi-region and multi-account deployments.

### Single Provider (Default):
```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "data" {
  bucket = "my-bucket"
  # Uses default provider (us-east-1)
}
```

### Multiple Providers with Aliases:
```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

resource "aws_s3_bucket" "primary" {
  bucket = "primary-bucket"
  # Uses default provider (us-east-1)
}

resource "aws_s3_bucket" "dr" {
  provider = aws.west  # ← Uses west provider
  bucket   = "dr-bucket"
}
```

## 💡 Why Use Multiple Providers?

### 1. **Disaster Recovery**
Deploy backup resources in different regions:
```hcl
resource "aws_s3_bucket" "primary" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "dr" {
  provider = aws.west
  region   = "us-west-2"
}
```

### 2. **Global Low Latency**
Serve users from nearby regions:
```hcl
resource "aws_dynamodb_table" "us" {
  # US users
}

resource "aws_dynamodb_table" "europe" {
  provider = aws.europe
  # European users
}
```

### 3. **Regulatory Compliance**
Keep data in specific jurisdictions:
```hcl
resource "aws_s3_bucket" "eu_data" {
  provider = aws.europe  # GDPR compliance
}
```

### 4. **Multi-Account Deployments**
```hcl
provider "aws" {
  alias  = "production"
  assume_role {
    role_arn = "arn:aws:iam::PROD_ACCOUNT:role/terraform"
  }
}

provider "aws" {
  alias  = "staging"
  assume_role {
    role_arn = "arn:aws:iam::STAGING_ACCOUNT:role/terraform"
  }
}
```

## 🚀 How to Use

### Deploy to all regions:
```bash
terraform init
terraform plan
terraform apply
```

### Verify resources in each region:
```bash
# US East (default)
aws s3 ls --region us-east-1

# US West (west provider)
aws s3 ls --region us-west-2

# Europe (europe provider)
aws s3 ls --region eu-west-1

# Mumbai (mumbai provider)
aws ec2 describe-vpcs --region ap-south-1
```

### View outputs:
```bash
terraform output regions_deployed
terraform output multi_region_summary
```

## 📊 Regions in This Example

| Region | Alias | Location | Purpose |
|:-------|:------|:---------|:--------|
| `us-east-1` | (default) | N. Virginia | Primary |
| `us-west-2` | `west` | Oregon | DR |
| `eu-west-1` | `europe` | Ireland | DR / EU Users |
| `ap-south-1` | `mumbai` | Mumbai | India Users |

## 🎨 Common Multi-Region Patterns

### Pattern 1: Primary + DR
```hcl
# Primary in us-east-1
resource "aws_db_instance" "primary" {
  # ... config ...
}

# DR in us-west-2
resource "aws_db_instance" "dr" {
  provider = aws.west
  # ... same config ...
}

# Set up replication
resource "aws_db_instance_replica" "dr_replica" {
  provider          = aws.west
  replicate_source_db = aws_db_instance.primary.id
}
```

### Pattern 2: Global Load Balancing
```hcl
# US
resource "aws_lb" "us" {
  # ...
}

# Europe  
resource "aws_lb" "eu" {
  provider = aws.europe
  # ...
}

# Route53 GeoDNS
resource "aws_route53_record" "global" {
  # Routes to nearest region
}
```

### Pattern 3: Regional Deployments
```hcl
locals {
  regions = {
    us_east = "us-east-1"
    us_west = "us-west-2"
    europe  = "eu-west-1"
    mumbai  = "ap-south-1"
  }
}

# Can't use for_each with providers directly
# But can use modules with provider aliasing
```

### Pattern 4: Cross-Region Replication
```hcl
# Source bucket
resource "aws_s3_bucket" "source" {
  bucket = "source-bucket"
}

resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Destination bucket
resource "aws_s3_bucket" "destination" {
  provider = aws.west
  bucket   = "destination-bucket"
}

resource "aws_s3_bucket_versioning" "destination" {
  provider = aws.west
  bucket   = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Replication configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.source.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket = aws_s3_bucket.destination.arn
    }
  }
}
```

## ⚠️ Important Considerations

### 1. Provider Aliases Are Required:
```hcl
# ❌ Wrong - can't have two providers without alias
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  region = "us-west-2"  # Error: duplicate provider!
}

# ✅ Correct - use aliases
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}
```

### 2. Explicit Provider References:
```hcl
resource "aws_s3_bucket" "west_bucket" {
  provider = aws.west  # Must specify alias
  bucket   = "my-bucket"
}
```

### 3. Data Sources Need Provider Too:
```hcl
data "aws_region" "west" {
  provider = aws.west
}
```

### 4. Modules and Providers:
```hcl
module "us_infrastructure" {
  source = "./modules/infrastructure"
  
  providers = {
    aws = aws  # Pass default provider
  }
}

module "eu_infrastructure" {
  source = "./modules/infrastructure"
  
  providers = {
    aws = aws.europe  # Pass europe provider
  }
}
```

## 📈 Best Practices

### 1. Use Clear Alias Names:
```hcl
# ✅ Good - describes region/purpose
provider "aws" {
  alias = "us_east_primary"
}

provider "aws" {
  alias = "us_west_dr"
}

# ❌ Bad - unclear
provider "aws" {
  alias = "provider2"
}
```

### 2. Use default_tags:
```hcl
provider "aws" {
  alias  = "west"
  region = "us-west-2"
  
  default_tags {
    tags = {
      Region    = "us-west-2"
      Purpose   = "DR"
      ManagedBy = "Terraform"
    }
  }
}
```

### 3. Document Region Strategy:
```hcl
# REGION STRATEGY:
# - us-east-1: Primary production (default provider)
# - us-west-2: DR site (west provider)
# - eu-west-1: EU GDPR compliance (europe provider)
# - ap-south-1: India regional (mumbai provider)
```

### 4. Keep Configurations Consistent:
```hcl
# Use variables for common settings
variable "vpc_cidr_prefix" {
  default = "10"
}

resource "aws_vpc" "us_east" {
  cidr_block = "${var.vpc_cidr_prefix}.0.0.0/16"
}

resource "aws_vpc" "us_west" {
  provider   = aws.west
  cidr_block = "${var.vpc_cidr_prefix}.1.0.0/16"
}
```

### 5. Use Modules for Reusability:
```hcl
module "infrastructure" {
  source = "./modules/regional-infra"
  
  for_each = var.regions
  
  providers = {
    aws = aws[each.key]  # Can't actually do this!
  }
}

# Note: You can't use for_each with providers
# Must explicitly create module calls per region
```

## 🔍 Common Issues

### Issue 1: Forgetting provider argument
```hcl
resource "aws_s3_bucket" "west_bucket" {
  bucket = "my-bucket"
  # Missing: provider = aws.west
  # Will use default provider!
}
```

### Issue 2: Cross-region references
```hcl
# ❌ Won't work - resources in different regions
resource "aws_lb_target_group" "app" {
  provider = aws.west
  vpc_id   = aws_vpc.us_east.id  # Different region!
}
```

### Issue 3: Implicit dependencies across regions
```hcl
# Be careful with dependencies
resource "aws_s3_bucket" "west" {
  provider = aws.west
  # ...
}

resource "aws_iam_role" "replication" {
  # Created in default region
  # Make sure it has permissions for west bucket
}
```

## 🎓 Real-World Use Cases

### Use Case 1: Netflix-Style Multi-Region
```hcl
# Application in every region for lowest latency
resource "aws_ecs_service" "us" { }
resource "aws_ecs_service" "eu" { provider = aws.europe }
resource "aws_ecs_service" "asia" { provider = aws.mumbai }

# Route53 routes to nearest region
resource "aws_route53_record" "global" {
  geolocation_routing_policy {
    # ...
  }
}
```

### Use Case 2: Banking - Regulatory Compliance
```hcl
# EU data must stay in EU
resource "aws_s3_bucket" "eu_customer_data" {
  provider = aws.europe
  # GDPR compliant
}

# US data stays in US
resource "aws_s3_bucket" "us_customer_data" {
  # US regulations
}
```

### Use Case 3: Gaming - Global Players
```hcl
# Game servers in each region
resource "aws_instance" "game_server_us" { }
resource "aws_instance" "game_server_eu" { provider = aws.europe }
resource "aws_instance" "game_server_asia" { provider = aws.mumbai }

# DynamoDB global tables for player data
```

### Use Case 4: SaaS - Tenant Isolation
```hcl
# Enterprise customers get their own region
resource "aws_rds_instance" "enterprise_customer_1" {
  provider = aws.west
  # Isolated in us-west-2
}

resource "aws_rds_instance" "enterprise_customer_2" {
  provider = aws.europe
  # Isolated in eu-west-1
}
```

## 📖 Summary

### Provider Meta-Argument Enables:
✅ Multi-region deployments  
✅ Disaster recovery setups  
✅ Global low-latency applications  
✅ Regulatory compliance  
✅ Multi-account architectures

### Key Points:
1. **Aliases required** for multiple providers
2. **Explicit provider** argument on resources
3. **Default provider** for resources without provider argument
4. **Data sources** need provider too
5. **Modules** can receive provider configurations

### Remember:
- **Plan region strategy** before implementation
- **Document why** each region is used
- **Test cross-region** features (replication, etc.)
- **Monitor costs** across all regions
- **Consider latency** for cross-region calls

**Multi-region = High availability + Low latency + Compliance! 🌍**
