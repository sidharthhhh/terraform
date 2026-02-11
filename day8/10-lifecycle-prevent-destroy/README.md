# Lifecycle: prevent_destroy Example

## 📚 What This Demonstrates
- Using `prevent_destroy` to protect critical resources
- Preventing accidental deletion of production data
- Best practices for resource protection
- How to override protection when necessary (emergency only)

## 🎯 What is prevent_destroy?

`prevent_destroy` is a safety mechanism that prevents Terraform from destroying a resource, even if you run `terraform destroy`.

### Without prevent_destroy:
```bash
$ terraform destroy
# ❌ Accidentally destroys production database!
# 😱 All data lost!
```

### With prevent_destroy:
```bash
$ terraform destroy
# ✅ ERROR: Cannot destroy - lifecycle prevent_destroy is set
# 😌 Data is safe!
```

## 💡 Why is This Critical?

### Real-World Disaster Scenarios:

1. **Accidental terraform destroy**:
   - Junior dev runs `terraform destroy` in production
   - Without protection → Database gone!
   - With protection → Error, database safe ✅

2. **Refactoring gone wrong**:
   - Rename a resource in code
   - Terraform sees it as delete + create
   - Without protection → Data deleted!
   - With protection → Error caught ✅

3. **Automated CI/CD mistake**:
   - Pipeline bug triggers destroy
   - Without protection → Everything gone!
   - With protection → Pipeline fails, resources safe ✅

## 🚀 How to Use

### Deploy the protected resources:
```bash
terraform init
terraform apply
```

### Test the protection:
```bash
# Try to destroy a protected resource
terraform destroy -target=aws_db_instance.production

# Expected output:
# Error: Instance cannot be destroyed as it is
# protected by lifecycle.prevent_destroy
```

### See which resources are protected:
```bash
terraform output protected_resources
```

## 📊 Resources That Should Use prevent_destroy

### ✅ Always Protect:

1. **Databases**:
   ```hcl
   resource "aws_db_instance" "production" {
     lifecycle {
       prevent_destroy = true
     }
   }
   ```
   **Why**: Contains critical business data

2. **S3 Buckets with Data**:
   ```hcl
   resource "aws_s3_bucket" "backups" {
     lifecycle {
       prevent_destroy = true
     }
   }
   ```
   **Why**: Backups, logs, important files

3. **KMS Keys**:
   ```hcl
   resource "aws_kms_key" "encryption" {
     lifecycle {
       prevent_destroy = true
     }
   }
   ```
   **Why**: Destroying makes encrypted data unreadable!

4. **DynamoDB Tables**:
   ```hcl
   resource "aws_dynamodb_table" "users" {
     lifecycle {
       prevent_destroy = true
     }
   }
   ```
   **Why**: User data, application state

5. **EBS Volumes with Data**:
   ```hcl
   resource "aws_ebs_volume" "data" {
     lifecycle {
       prevent_destroy = true
     }
   }
   ```
   **Why**: Persistent storage

6. **Container Registries**:
   ```hcl
   resource "aws_ecr_repository" "production" {
     lifecycle {
       prevent_destroy = true
     }
   }
   ```
   **Why**: Production container images

### ❌ Don't Need Protection:

- Ephemeral compute (EC2 instances, Lambda functions)
- Network resources (VPCs, Subnets - no data)
- IAM roles/policies (can be recreated)
- CloudWatch log groups (if retention is OK)

## ⚠️ Important Behaviors

### What prevent_destroy Protects Against:

✅ `terraform destroy`
✅ `terraform destroy -target=resource`  
✅ Resource renamed (delete + create)
✅ Resource moved to different state
✅ Attribute change requiring replacement

### What it Doesn NOT Protect Against:

❌ Manual deletion in AWS Console
❌ `terraform state rm` (removes from state, not AWS)
❌ AWS CLI/API deletion
❌ Account closure
❌ Resource deletion by other tools

## 🔧 How to Destroy When Necessary

Sometimes you legitimately need to destroy a protected resource (e.g., decommissioning).

### Option 1: Remove from State (Safest)
```bash
# Remove from Terraform management
terraform state rm aws_db_instance.production

# Manually delete in AWS Console if needed
# (Or keep it running outside Terraform)
```

### Option 2: Temporarily Disable (CAREFUL!)
```bash
# 1. Edit main.tf - comment out lifecycle block
resource "aws_db_instance" "production" {
  # ...
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# 2. Apply the change
terraform apply

# 3. Now you can destroy
terraform destroy

# 4. ⚠️ IMPORTANT: Restore lifecycle block for other environments!
```

### Option 3: Targeted State Removal
```bash
# For multiple resources
terraform state list | grep production | xargs -n1 terraform state rm
```

## 🎨 Real-World Patterns

### Pattern 1: Environment-Specific Protection
```hcl
variable "environment" {
  type = string
}

resource "aws_db_instance" "database" {
  identifier = "${var.environment}-database"
  # ...
  
  lifecycle {
    # Only protect production
    prevent_destroy = var.environment == "production" ? true : false
  }
}
```

### Pattern 2: Protection with Conditions
```hcl
locals {
  is_production = var.environment == "production"
  has_data      = var.database_size_gb > 0
}

resource "aws_db_instance" "database" {
  lifecycle {
    prevent_destroy = local.is_production && local.has_data
  }
}
```

### Pattern 3: Layered Protection
```hcl
resource "aws_db_instance" "database" {
  skip_final_snapshot = false
  final_snapshot_identifier = "final-backup-${timestamp()}"
  deletion_protection = true  # AWS-level protection
  
  lifecycle {
    prevent_destroy = true    # Terraform-level protection
  }
}
```

## 📈 Best Practices

### 1. Tag Protected Resources:
```hcl
tags = {
  Protection  = "prevent_destroy enabled"
  Critical    = "true"
  DataLoss    = "catastrophic"
}
```

### 2. Document Why:
```hcl
resource "aws_db_instance" "production" {
  # ...
  
  lifecycle {
    prevent_destroy = true
  }
  
  # IMPORTANT: This database contains production customer data.
  # Cannot be destroyed without executive approval and backup verification.
}
```

### 3. Separate Critical Resources:
```hcl
# critical.tf - All protected resources
# standard.tf - Normal resources
```

### 4. Use with Backup Strategies:
```hcl
resource "aws_db_instance" "production" {
  backup_retention_period = 30
  skip_final_snapshot     = false
  
  lifecycle {
    prevent_destroy = true
  }
}
```

### 5. Combine with Other Protections:
```hcl
resource "aws_db_instance" "production" {
  deletion_protection = true  # AWS protection
  
  lifecycle {
    prevent_destroy = true    # Terraform protection
  }
}
```

## 🔍 Testing prevent_destroy

### Test 1: Try Targeted Destroy
```bash
terraform destroy -target=aws_db_instance.production

# Expected: ERROR ❌
# "Instance cannot be destroyed..."
```

### Test 2: Try Full Destroy
```bash
terraform destroy

# Expected: Plan shows everything except protected resources
# Then ERROR when it tries to destroy protected ones ❌
```

### Test 3: Try Resource Rename
```bash
# In main.tf, rename:
# resource "aws_db_instance" "production" {
# to:
# resource "aws_db_instance" "prod_database" {

terraform plan

# Expected: ERROR ❌
# Terraform sees this as delete + create
# Delete is blocked by prevent_destroy
```

## ⚠️ Common Issues

### Issue 1: Can't Destroy Stack
**Symptom**: `terraform destroy` fails
**Cause**: Protected resources exist
**Solution**: This is correct! Remove resources from state first.

### Issue 2: Can't Refactor
**Symptom**: Renaming resource fails
**Cause**: Terraform sees rename as delete + create
**Solution**:
```bash
# Use terraform state mv instead
terraform state mv aws_db_instance.old aws_db_instance.new
```

### Issue 3: Accidentally Deleted in Console
**Symptom**: Resource deleted in AWS but Terraform doesn't know
**Solution**:
```bash
# Remove from state
terraform state rm aws_db_instance.production
```

## 🎓 When to Use

### ✅ Use prevent_destroy for:
- Production databases
- Backup storage
- Encryption keys
- Stateful services
- Container registries
- Any resource with irreplaceable data

### ❌ Don't use for:
- Development environments
- Stateless compute
- Easily recreatable resources
- Temporary resources

## 📖 Emergency Procedures

### Emergency Destroy Checklist:

1. ✅ Executive/Team approval obtained
2. ✅ Full backup verified
3. ✅ Backup tested (restore works)
4. ✅ Downtime window scheduled
5. ✅ Rollback plan documented
6. ✅ Team notified
7. ✅ Temporarily disable prevent_destroy
8. ✅ Execute destroy
9. ✅ verify destruction
10. ✅ Re-enable prevent_destroy in code

### Backup Before Destroy:
```bash
# Database
aws rds create-db-snapshot --db-instance-identifier production-db

# S3
aws s3 sync s3://critical-bucket s3://backup-bucket

# DynamoDB
aws dynamodb create-backup --table-name production-table
```

## 💡 Key Takeaways

1. **prevent_destroy is a safety net**, not security
2. **Use for all production data resources**
3. **Combine with AWS-level protections**
4. **Document protected resources clearly**
5. **Test protection regularly**
6. **Have emergency procedures ready**
7. **Always backup before override**

Remember: **Prevention is better than recovery!** 🛡️
