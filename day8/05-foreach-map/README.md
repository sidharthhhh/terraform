# For_Each with Map Example

## 📚 What This Demonstrates
- Using `for_each` with maps (key-value pairs)
- Complex object types in maps
- Conditional for_each with filtering
- Combining for_each with dynamic blocks
- Merging tags from multiple sources
- Grouping and filtering in outputs

## 🎯 Key Concepts

### For_Each with Map
```hcl
variable "servers" {
  type = map(object({
    instance_type = string
    ami           = string
  }))
  default = {
    "web" = {
      instance_type = "t2.micro"
      ami           = "ami-12345"
    }
    "db" = {
      instance_type = "t2.small"
      ami           = "ami-67890"
    }
  }
}

resource "aws_instance" "servers" {
  for_each = var.servers
  
  # each.key = "web" or "db"
  # each.value = the object (instance_type, ami)
  instance_type = each.value.instance_type
  ami           = each.value.ami
  
  tags = {
    Name = each.key
  }
}
```

### Filtered For_Each
```hcl
# Only create for items matching a condition
resource "aws_s3_bucket_versioning" "versioning" {
  for_each = {
    for key, config in var.buckets : key => config
    if config.versioning_enabled  # Filter condition
  }
  
  bucket = aws_s3_bucket.buckets[each.key].id
}
```

### Dynamic Blocks with For_Each
```hcl
dynamic "rule" {
  for_each = each.value.environment == "production" ? [1] : []
  
  content {
    # Rule only added for production
  }
}
```

## 🚀 How to Use

### Default configuration:
```bash
terraform init
terraform apply
```

### Custom configuration with terraform.tfvars:
```hcl
buckets = {
  "critical-data" = {
    versioning_enabled = true
    lifecycle_days     = 2555
    environment        = "production"
    purpose            = "critical-business-data"
  }
  "analytics" = {
    versioning_enabled = true
    lifecycle_days     = 180
    environment        = "production"
    purpose            = "analytics-data"
  }
  "test-data" = {
    versioning_enabled = false
    lifecycle_days     = 1
    environment        = "development"
    purpose            = "testing"
  }
}
```

### Viewing specific outputs:
```bash
# All buckets
terraform output all_buckets

# Only production buckets
terraform output production_buckets

# Versioned buckets
terraform output versioned_buckets

# Summary stats
terraform output summary
```

## 📊 What Gets Created (Default)

### 4 S3 Buckets:
1. **app-logs-production-{account}**
   - Versioning: ✅ Enabled
   - Lifecycle: 30 days
   - Intelligent Tiering: ✅
   
2. **user-data-production-{account}**
   - Versioning: ✅ Enabled
   - Lifecycle: 90 days
   - Intelligent Tiering: ✅
   
3. **temp-storage-development-{account}**
   - Versioning: ❌ Disabled
   - Lifecycle: 7 days
   - Intelligent Tiering: ❌
   
4. **backups-production-{account}**
   - Versioning: ✅ Enabled
   - Lifecycle: 365 days
   - Intelligent Tiering: ✅

## 💡 Key Takeaways

### Map Advantages:
1. **Named Keys**: Access by name, not number
2. **Self-Documenting**: Key describes the resource
3. **Flexible**: Each value can have different properties
4. **Stable**: Adding/removing doesn't affect others

### Each in Maps:
- `each.key` = The map key (string)
- `each.value` = The map value (can be object, string, number, etc.)

### Filtering:
```hcl
# Create a filtered map
{
  for key, value in var.map : key => value
  if value.condition == true
}
```

## 🎨 Advanced Patterns

### 1. Conditional Resources
```hcl
# Only enable versioning where configured
for_each = {
  for key, config in var.buckets : key => config
  if config.versioning_enabled
}
```

### 2. Tag Merging
```hcl
tags = merge(
  { Name = each.key },
  var.common_tags,
  var.environment_tags[each.value.environment]
)
```

### 3. Environment-Specific Behavior
```hcl
dynamic "rule" {
  for_each = each.value.environment == "production" ? [1] : []
  content {
    # Production-only configuration
  }
}
```

### 4. Grouping in Outputs
```hcl
output "by_environment" {
  value = {
    production  = [for k, v in var.buckets : k if v.environment == "production"]
    development = [for k, v in var.buckets : k if v.environment == "development"]
  }
}
```

## 🔄 Modifying the Map

### Adding a New Bucket:
```hcl
buckets = {
  # ... existing buckets ...
  "new-bucket" = {
    versioning_enabled = true
    lifecycle_days     = 60
    environment        = "production"
    purpose            = "new-feature-data"
  }
}
```
**Result**: Only the new bucket is created. Existing buckets unchanged! ✅

### Removing a Bucket:
```hcl
buckets = {
  # Remove "temp-storage"
  "app-logs"   = { ... }
  "user-data"  = { ... }
  "backups"    = { ... }
}
```
**Result**: Only "temp-storage" is destroyed. Others unchanged! ✅

### Modifying Properties:
```hcl
"app-logs" = {
  versioning_enabled = true
  lifecycle_days     = 60  # Changed from 30
  environment        = "production"
  purpose            = "application-logs"
}
```
**Result**: Only the lifecycle configuration is updated! ✅

## ⚠️ Common Pitfalls

### 1. Changing Keys
```hcl
# Before
"app-logs" = { ... }

# After (renamed)
"application-logs" = { ... }
```
**Result**: Old resource destroyed, new one created (because key changed)

**Solution**: Use `moved` block or keep keys stable

### 2. Using Lists Instead of Maps
```hcl
# ❌ Wrong for complex data
variable "buckets" {
  type = list(object({ ... }))
}

# ✅ Correct
variable "buckets" {
  type = map(object({ ... }))
}
```

### 3. Forgetting to Convert Lists
```hcl
# If you have a list
variable "names" {
  type    = list(string)
  default = ["a", "b", "c"]
}

# Convert to set for for_each
resource "..." {
  for_each = toset(var.names)
  # ...
}
```

## 🎓 Real-World Use Cases
- Multi-environment infrastructure (prod, staging, dev)
- Per-team AWS resources
- Application-specific configurations
- Service mesh configurations
- Multi-tenant deployments

## 📈 Comparison Table

| Feature | for_each (Map) | for_each (Set) | count |
|:--------|:---------------|:---------------|:------|
| Key Type | String | String | Numeric |
| Value Type | Anything | String only | N/A |
| Access | `["key"]` | `["value"]` | `[0]` |
| Metadata | ✅ Rich | ⚠️ Limited | ❌ None |
| Best For | Complex config | Simple lists | Fixed numbers |
