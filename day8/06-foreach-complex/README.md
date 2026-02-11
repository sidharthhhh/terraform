# For_Each Complex Example - Real-World Application Stacks

## 📚 What This Demonstrates
- **Nested data structures** with for_each
- **Flattening nested maps** for resource creation
- **Cross-resource references** in complex scenarios
- **Conditional resource creation** based on nested properties
- **Dynamic IAM policies** referencing other for_each resources
- **Advanced output transformations** and grouping
- **Real-world multi-stack architecture**

## 🎯 Key Concepts

### 1. Flattening Nested Structures
```hcl
# Input: Nested map of stacks -> buckets
variable "stacks" {
  type = map(object({
    buckets = map(object({
      versioning = bool
    }))
  }))
}

# Flatten for for_each
for_each = merge([
  for stack_key, stack in var.stacks : {
    for bucket_key, bucket_config in stack.buckets :
    "${stack_key}-${bucket_key}" => {
      stack_name = stack_key
      bucket_key = bucket_key
      config     = bucket_config
    }
  }
]...)
```

### 2. Filtered For_Each from Nested Data
```hcl
# Only create versioning for buckets where versioning = true
for_each = {
  for key, bucket in aws_s3_bucket.buckets : key => bucket
  if lookup_nested_config(key).versioning  # Simplified
}
```

### 3. Cross-Resource References
```hcl
# IAM policy referencing buckets from same stack
Resource = [
  for bucket_key in keys(each.value.buckets) :
  aws_s3_bucket.buckets["${each.key}-${bucket_key}"].arn
]
```

## 🏗️ Architecture

This example creates a complete application stack for each environment:

```
Stack (e.g., "web-app-prod")
├── S3 Buckets (assets, logs)
│   ├── Versioning (conditional)
│   ├── Encryption (conditional)
│   └── Lifecycle Rules
├── ECR Repositories (frontend, backend, api)
│   └── Image scanning (prod only)
├── IAM Role
│   └── S3 Access Policy (to own buckets)
├── SSM Parameters (DB config)
└── SNS Topic (notifications)
```

## 📊 What Gets Created (Default)

### Web-App-Prod Stack:
- **S3 Buckets**: 
  - `web-app-prod-assets-production` (versioned, encrypted, 90-day lifecycle)
  - `web-app-prod-logs-production` (versioned, encrypted, 30-day lifecycle)
- **ECR Repositories**:
  - `web-app-prod-frontend` (scan on push)
  - `web-app-prod-backend` (scan on push)
  - `web-app-prod-api` (scan on push)
- **IAM Role**: `web-app-prod-application-role`
- **SSM Parameter**: `/web-app-prod/database/config`
- **SNS Topic**: `web-app-prod-notifications`

### Web-App-Staging Stack:
- **S3 Buckets**:
  - `web-app-staging-assets-staging` (not versioned, encrypted, 7-day lifecycle)
- **ECR Repositories**:
  - `web-app-staging-frontend` (no scan)
  - `web-app-staging-backend` (no scan)
- **IAM Role**: `web-app-staging-application-role`
- **SSM Parameter**: `/web-app-staging/database/config`
- **SNS Topic**: `web-app-staging-notifications`

## 🚀 How to Use

### Deploy with defaults:
```bash
terraform init
terraform apply
```

### View specific outputs:
```bash
# All buckets
terraform output all_buckets

# Buckets grouped by stack
terraform output buckets_by_stack

# Repositories by stack
terraform output repositories_by_stack

# Summary of everything
terraform output stack_summary

# Only production resources
terraform output production_resources
```

## 💡 Advanced Patterns Explained

### Pattern 1: Nested Map Flattening
```hcl
# Problem: Create resources from nested structure
application_stacks = {
  "app1" = {
    buckets = {
      "logs"  = { ... }
      "data"  = { ... }
    }
  }
  "app2" = {
    buckets = {
      "assets" = { ... }
    }
  }
}

# Solution: Flatten to single-level map
merge([
  for stack_key, stack in var.application_stacks : {
    for bucket_key, config in stack.buckets :
    "${stack_key}-${bucket_key}" => {
      # Combined key: "app1-logs", "app1-data", "app2-assets"
      stack_name = stack_key
      bucket_key = bucket_key
      config     = config
    }
  }
]...)

# Result:
# {
#   "app1-logs"   = { stack_name = "app1", bucket_key = "logs", ... }
#   "app1-data"   = { stack_name = "app1", bucket_key = "data", ... }
#   "app2-assets" = { stack_name = "app2", bucket_key = "assets", ... }
# }
```

### Pattern 2: Cross-Stack Resource References
```hcl
# Access bucket ARNs from the same stack only
policy = jsonencode({
  Resource = [
    for bucket_key in keys(each.value.buckets) :
    aws_s3_bucket.app_buckets["${each.key}-${bucket_key}"].arn
  ]
})

# For "web-app-prod" stack, this creates:
# ["arn:aws:s3:::web-app-prod-assets", "arn:aws:s3:::web-app-prod-logs"]
```

### Pattern 3: Environment-Specific Configuration
```hcl
image_scanning_configuration {
  scan_on_push = each.value.environment == "production" ? true : false
}

# Production repos: scanning enabled
# Non-production: scanning disabled
```

### Pattern 4: Grouped Outputs
```hcl
output "buckets_by_stack" {
  value = {
    for stack_key in keys(var.application_stacks) : stack_key => {
      for bucket_key, bucket in aws_s3_bucket.app_buckets :
      bucket_key => bucket.bucket
      if startswith(bucket_key, stack_key)  # Filter by stack
    }
  }
}

# Result:
# {
#   "web-app-prod" = {
#     "web-app-prod-assets" = "web-app-prod-assets-production"
#     "web-app-prod-logs"   = "web-app-prod-logs-production"
#   }
#   "web-app-staging" = {
#     "web-app-staging-assets" = "web-app-staging-assets-staging"
#   }
# }
```

## 🎨 Adding a New Stack

Create `terraform.tfvars`:
```hcl
application_stacks = {
  "web-app-prod" = {
    environment = "production"
    vpc_cidr    = "10.0.0.0/16"
    buckets = {
      "assets" = {
        versioning     = true
        encryption     = true
        lifecycle_days = 90
      }
      "logs" = {
        versioning     = true
        encryption     = true
        lifecycle_days = 30
      }
    }
    repositories = ["frontend", "backend", "api"]
    db_config = {
      engine         = "postgres"
      instance_class = "db.t3.medium"
      storage_gb     = 100
    }
  }
  # Add new stack
  "mobile-app-prod" = {
    environment = "production"
    vpc_cidr    = "10.2.0.0/16"
    buckets = {
      "uploads" = {
        versioning     = true
        encryption     = true
        lifecycle_days = 180
      }
    }
    repositories = ["ios-app", "android-app"]
    db_config = {
      engine         = "postgres"
      instance_class = "db.t3.small"
      storage_gb     = 50
    }
  }
}
```

Result: Complete new stack created with all resources!

## ⚠️ Important Considerations

### Performance:
- Many nested loops can be slow
- Terraform must evaluate all expressions
- Keep nesting to 2-3 levels maximum

### State Management:
- Each flattened key must be unique
- Changing keys destroys and recreates resources
- Use consistent naming schemes

### Debugging:
```bash
# See the flattened structure
terraform console
> merge([for stack_key, stack in var.application_stacks : { for bucket_key, bucket_config in stack.buckets : "${stack_key}-${bucket_key}" => bucket_config }]...)
```

## 🎓 Real-World Use Cases
- Multi-tenant SaaS applications
- Environment-specific infrastructure (dev, staging, prod)
- Microservices with shared infrastructure patterns
- Team-specific AWS resources
- Region-specific deployments

## 📈 Key Takeaways
1. **Flatten nested structures** using nested for expressions
2. **merge([...]...)** combines multiple maps into one
3. **Cross-reference resources** using composite keys
4. **Filter and group** in outputs for better organization
5. **Keep it maintainable** - don't over-complicate
6. **Document heavily** - nested for_each can be hard to understand

## 🔍 When NOT to Use This
- Simple, flat resource lists (use simple for_each)
- Deeply nested structures (>3 levels - consider modules)
- When readability suffers
- When debugging becomes difficult

**→ Consider using modules instead for very complex scenarios**
