output "s3_buckets" {
  description = "S3 buckets in all regions"
  value = {
    primary_us_east = aws_s3_bucket.primary.bucket
    dr_us_west      = aws_s3_bucket.dr_west.bucket
    dr_europe       = aws_s3_bucket.dr_europe.bucket
  }
}

output "vpc_ids" {
  description = "VPC IDs in all regions"
  value = {
    us_east_1 = aws_vpc.us_east.id
    us_west_2 = aws_vpc.us_west.id
    mumbai    = aws_vpc.mumbai.id
  }
}

output "dynamodb_tables" {
  description = "DynamoDB tables in multiple regions"
  value = {
    us_east = aws_dynamodb_table.users_us_east.name
    mumbai  = aws_dynamodb_table.users_mumbai.name
  }
}

output "ecr_repositories" {
  description = "ECR repository URLs"
  value = {
    us_east = aws_ecr_repository.app_us_east.repository_url
    us_west = aws_ecr_repository.app_us_west.repository_url
  }
}

output "kms_keys" {
  description = "KMS key ARNs by region"
  value = {
    us_east = aws_kms_key.us_east.arn
    mumbai  = aws_kms_key.mumbai.arn
  }
}

output "regions_deployed" {
  description = "List of regions where resources are deployed"
  value = [
    "us-east-1 (N. Virginia) - Primary",
    "us-west-2 (Oregon) - DR",
    "eu-west-1 (Ireland) - DR",
    "ap-south-1 (Mumbai) - Regional"
  ]
}

output "multi_region_summary" {
  description = "Summary of multi-region deployment"
  value = {
    total_regions    = 4
    primary_region   = "us-east-1"
    dr_regions       = ["us-west-2", "eu-west-1"]
    regional         = ["ap-south-1"]
    s3_buckets       = 3
    vpcs             = 3
    dynamodb_tables  = 2
    ecr_repositories = 2
    kms_keys         = 2
  }
}

output "provider_usage" {
  description = "How providers are used"
  value       = <<-EOT
    PROVIDER CONFIGURATION:
    
    Default Provider (no alias):
    ─────────────────────────────
    provider "aws" {
      region = "us-east-1"
    }
    Used by: Resources without explicit provider argument
    
    West Provider (alias: west):
    ────────────────────────────
    provider "aws" {
      alias  = "west"
      region = "us-west-2"
    }
    Used by: Resources with provider = aws.west
    
    Europe Provider (alias: europe):
    ────────────────────────────────
    provider "aws" {
      alias  = "europe"
      region = "eu-west-1"
    }
    Used by: Resources with provider = aws.europe
    
    Mumbai Provider (alias: mumbai):
    ────────────────────────────────
    provider "aws" {
      alias  = "mumbai"
      region = "ap-south-1"
    }
    Used by: Resources with provider = aws.mumbai
  EOT
}

output "cross_region_replication_setup" {
  description = "How to set up cross-region replication"
  value       = <<-EOT
    CROSS-REGION S3 REPLICATION EXAMPLE:
    
    1. Enable versioning on both buckets (already done)
    
    2. Create replication rule:
       aws_s3_bucket_replication_configuration "primary_to_west" {
         role   = aws_iam_role.replication.arn
         bucket = aws_s3_bucket.primary.id
         
         rule {
           id     = "replicate-to-west"
           status = "Enabled"
           
           destination {
             bucket = aws_s3_bucket.dr_west.arn
           }
         }
       }
    
    3. Create IAM role with permissions
    
    4. Objects in primary bucket auto-replicate to DR bucket!
  EOT
}

output "testing_instructions" {
  description = "How to verify multi-region deployment"
  value       = <<-EOT
    TESTING MULTI-REGION DEPLOYMENT:
    
    1. Verify S3 buckets in each region:
       aws s3 ls --region us-east-1 | grep primary
       aws s3 ls --region us-west-2 | grep dr-west
       aws s3 ls --region eu-west-1 | grep dr-europe
    
    2. Verify VPCs:
       aws ec2 describe-vpcs --region us-east-1
       aws ec2 describe-vpcs --region us-west-2
       aws ec2 describe-vpcs --region ap-south-1
    
    3. Test cross-region latency:
       # Upload to us-east-1
       echo "test" | aws s3 cp - s3://primary-bucket/test.txt
       
       # Can access from any region!
       aws s3 cp s3://primary-bucket/test.txt - --region us-east-1
       aws s3 cp s3://primary-bucket/test.txt - --region ap-south-1
    
    4. Check DynamoDB global tables (manual setup required):
       aws dynamodb describe-table --table-name users-us-east --region us-east-1
       aws dynamodb describe-table --table-name users-mumbai --region ap-south-1
  EOT
}
