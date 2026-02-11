output "production_db_endpoint" {
  description = "Production database endpoint"
  value       = aws_db_instance.production.endpoint
}

output "production_db_identifier" {
  description = "Production database identifier"
  value       = aws_db_instance.production.identifier
}

output "critical_backup_bucket" {
  description = "Critical backup S3 bucket name"
  value       = aws_s3_bucket.critical_backups.id
}

output "kms_key_id" {
  description = "Production KMS key ID"
  value       = aws_kms_key.production_key.id
}

output "kms_key_arn" {
  description = "Production KMS key ARN"
  value       = aws_kms_key.production_key.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.user_data.name
}

output "ebs_volume_id" {
  description = "Critical EBS volume ID"
  value       = aws_ebs_volume.critical_data.id
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.production_app.repository_url
}

output "protected_resources" {
  description = "List of resources protected by prevent_destroy"
  value = {
    database       = aws_db_instance.production.identifier
    backup_bucket  = aws_s3_bucket.critical_backups.id
    kms_key        = aws_kms_key.production_key.id
    dynamodb_table = aws_dynamodb_table.user_data.name
    ebs_volume     = aws_ebs_volume.critical_data.id
    ecr_repository = aws_ecr_repository.production_app.name
  }
}

output "how_to_destroy_if_needed" {
  description = "Instructions for destroying protected resources when necessary"
  value       = <<-EOT
    ⚠️  PROTECTED RESOURCES CANNOT BE DESTROYED WITH TERRAFORM DESTROY
    
    These resources have lifecycle { prevent_destroy = true }
    
    If you MUST destroy them (e.g., decommissioning environment):
    
    Option 1: Remove from Terraform State (keeps resource in AWS)
    ========================================================
    terraform state rm aws_db_instance.production
    terraform state rm aws_s3_bucket.critical_backups
    # ... (for each protected resource)
    
    Option 2: Temporarily Disable Protection (DANGEROUS!)
    ======================================================
    1. Comment out the lifecycle block:
       # lifecycle {
       #   prevent_destroy = true
       # }
    
    2. Run terraform apply (to update state)
    
    3. Run terraform destroy
    
    4. RESTORE the lifecycle block for other environments!
    
    Option 3: Manual Deletion in AWS Console
    =========================================
    1. Remove resources from Terraform:
       terraform state rm <resource_address>
    
    2. Manually delete in AWS Console
    
    ⚠️  ALWAYS take backups before destroying production resources!
  EOT
}

output "test_prevent_destroy" {
  description = "How to test prevent_destroy protection"
  value       = <<-EOT
    TEST PREVENT_DESTROY:
    
    1. Try to destroy a specific resource:
       terraform destroy -target=aws_db_instance.production
    
       Result: ERROR! ❌
       "Instance cannot be destroyed as it has lifecycle.prevent_destroy"
    
    2. Try to destroy entire stack:
       terraform destroy
    
       Result: ERROR! ❌
       Will fail when it tries to destroy protected resources
    
    3. This is EXPECTED and CORRECT behavior!
       prevent_destroy is working as intended ✅
  EOT
}
