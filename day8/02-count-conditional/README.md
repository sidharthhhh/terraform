# Count Conditional Example

## 📚 What This Demonstrates
- Using conditional expressions with count
- Creating resources based on variable conditions
- Using ternary operators: `condition ? true_value : false_value`
- Environment-specific resource creation
- Partial resource creation (lifecycle on first 2 buckets only)

## 🎯 Key Concepts

### Conditional Count
```hcl
count = var.create_buckets ? var.bucket_count : 0
# If create_buckets is true, create var.bucket_count instances
# Otherwise, create 0 instances (nothing)
```

### Environment-Specific Resources
```hcl
count = var.environment == "production" ? 3 : 0
# Only create in production environment
```

### Partial Creation
```hcl
count = min(var.bucket_count, 2)
# Create at most 2 instances, even if bucket_count is higher
```

## 🚀 How to Use

### Test 1: Create buckets (default)
```bash
terraform init
terraform apply
```

### Test 2: Don't create buckets
```bash
terraform apply -var="create_buckets=false"
```

### Test 3: Create different number of buckets
```bash
terraform apply -var="bucket_count=5"
```

### Test 4: Production environment
```bash
terraform apply -var="environment=production"
```

### Test 5: Mix conditions
```bash
terraform apply -var="environment=production" -var="bucket_count=4"
```

## 📊 Behavior Matrix

| create_buckets | bucket_count | Buckets Created | Logging | Lifecycle Rules |
|:---------------|:-------------|:----------------|:--------|:----------------|
| true           | 3            | 3               | Only if prod | 2 (first two) |
| true           | 5            | 5               | Only if prod | 2 (first two) |
| false          | 3            | 0               | 0 | 0 |
| true (prod)    | 3            | 3               | 3 | 2 |

## 💡 Key Takeaways
- Use ternary for conditional creation: `condition ? count_value : 0`
- Count can be calculated from variables and expressions
- Setting count to 0 creates no resources
- Different resources can have different conditional counts
- Useful for environment-specific resources

## ⚠️ Common Patterns

### Enable/Disable Feature
```hcl
count = var.enable_feature ? 1 : 0
```

### Environment-Specific
```hcl
count = var.environment == "production" ? 1 : 0
```

### Variable-Based Count
```hcl
count = var.instance_count
```

### Calculated Count
```hcl
count = length(var.availability_zones)
```

## 🎓 Real-World Use Cases
- Create backup buckets only in production
- Enable monitoring only for certain environments
- Scale resources based on variable input
- Conditional feature flags
