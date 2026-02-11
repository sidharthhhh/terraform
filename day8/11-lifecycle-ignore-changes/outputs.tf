output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.app.name
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.app.function_name
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.app.endpoint
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.data.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.app.id
}

output "ignored_attributes" {
  description = "Summary of ignored attributes per resource"
  value = {
    asg = {
      resource         = "aws_autoscaling_group.app"
      ignored          = ["desired_capacity", "load_balancers", "target_group_arns"]
      reason           = "Auto-scaling changes these dynamically"
      external_manager = "AWS Auto Scaling"
    }
    ec2_instance = {
      resource         = "aws_instance.web"
      ignored          = ["tags['SSMManaged']", "tags['BackupPolicy']", "tags['MonitoringEnabled']", "tags['LastPatched']"]
      reason           = "External tools add operational tags"
      external_manager = "AWS Systems Manager, AWS Backup, Monitoring Tools"
    }
    lambda = {
      resource         = "aws_lambda_function.app"
      ignored          = ["filename", "source_code_hash", "last_modified", "environment.variables['DEBUG_MODE']"]
      reason           = "Code deployed via CI/CD, debug mode changed by ops"
      external_manager = "CI/CD Pipeline, Operations Team"
    }
    database = {
      resource         = "aws_db_instance.app"
      ignored          = ["password", "engine_version"]
      reason           = "Password rotated by Secrets Manager, minor versions auto-upgraded"
      external_manager = "AWS Secrets Manager, AWS RDS Auto Upgrade"
    }
    s3_lifecycle = {
      resource         = "aws_s3_bucket_lifecycle_configuration.data"
      ignored          = ["rule"]
      reason           = "Lifecycle rules managed by governance tools"
      external_manager = "Cloud Governance Tool"
    }
    security_group = {
      resource         = "aws_security_group.app"
      ignored          = ["ingress", "egress"]
      reason           = "Ops team adds temporary rules for troubleshooting"
      external_manager = "Operations Team"
    }
  }
}

output "drift_warning" {
  description = "Important notes about configuration drift"
  value       = <<-EOT
    ⚠️  CONFIGURATION DRIFT WARNING
    
    Resources in this configuration use ignore_changes lifecycle rules.
    
    This means:
    1. Terraform will NOT revert changes made outside Terraform
    2. Actual AWS state may differ from Terraform configuration
    3. You should monitor drift using other tools
    
    To check for drift:
    ────────────────────────────────────────────────────────────
    terraform plan -refresh-only
    
    To see current actual values:
    ────────────────────────────────────────────────────────────
    terraform show
    
    To force Terraform to manage ignored attributes again:
    ────────────────────────────────────────────────────────────
    1. Remove the ignore_changes rules
    2. Run: terraform plan
    3. Review changes carefully!
    4. Run: terraform apply
  EOT
}

output "use_cases_summary" {
  description = "When to use ignore_changes"
  value = {
    auto_scaling     = "ASG desired_capacity changes based on metrics"
    external_tags    = "Tags added by monitoring, backup, or management tools"
    cicd_deployments = "Application code deployed outside Terraform"
    secret_rotation  = "Passwords rotated by secrets management systems"
    auto_upgrades    = "Minor version upgrades done automatically"
    debug_rules      = "Temporary security group rules for troubleshooting"
  }
}
