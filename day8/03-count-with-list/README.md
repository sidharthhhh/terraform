# Count with List Example

## 📚 What This Demonstrates
- Using count with `length()` function
- Creating resources from string lists
- Creating resources from object lists
- Accessing list elements using `count.index`
- Filtering lists with for expressions
- Working with complex object structures

## 🎯 Key Concepts

### Count with Simple List
```hcl
variable "names" {
  default = ["alice", "bob", "charlie"]
}

resource "aws_iam_user" "users" {
  count = length(var.names)
  name  = var.names[count.index]
}
```

### Count with Object List
```hcl
variable "configs" {
  type = list(object({
    name  = string
    size  = number
  }))
}

resource "aws_instance" "servers" {
  count         = length(var.configs)
  instance_type = var.configs[count.index].size
}
```

### Filtering Lists
```hcl
count = length([
  for item in var.list : item if item.enabled
])
```

## 🚀 How to Use

### Default configuration:
```bash
terraform init
terraform apply
```

### Custom configurations:
```bash
# Custom bucket list
terraform apply -var='bucket_configs=["bucket1","bucket2"]'

# Custom user list
terraform apply -var='iam_users=["user1","user2","user3","user4"]'
```

### With terraform.tfvars:
Create a `terraform.tfvars` file:
```hcl
bucket_configs = ["analytics", "reports", "backups"]

iam_users = ["developer1", "developer2", "admin"]

advanced_bucket_configs = [
  {
    name           = "critical-data"
    versioning     = true
    lifecycle_days = 90
  },
  {
    name           = "temp-data"
    versioning     = false
    lifecycle_days = 1
  }
]
```

Then apply:
```bash
terraform apply
```

## 📊 What Gets Created

### Simple Buckets (4 buckets)
- `data-lake-{account_id}`
- `backups-{account_id}`
- `logs-{account_id}`
- `archives-{account_id}`

### IAM Users (3 users)
- `alice`
- `bob`
- `charlie`

### Advanced Buckets (3 buckets)
- `production-data-adv-{account_id}` (versioned, 30-day lifecycle)
- `staging-data-adv-{account_id}` (no versioning, 7-day lifecycle)
- `development-data-adv-{account_id}` (no versioning, 3-day lifecycle)

## 💡 Key Takeaways
- Use `length(var.list)` to get count from list size
- Access list elements with `count.index`
- Works with both simple lists and complex object lists
- Can filter lists using for expressions
- Properties from objects can be accessed using `var.list[count.index].property`

## ⚠️ Limitations of Count with Lists

### Problem: Order Matters
If you remove an item from the middle of the list:
```hcl
# Before
bucket_configs = ["bucket1", "bucket2", "bucket3"]

# After removing bucket2
bucket_configs = ["bucket1", "bucket3"]
```

Terraform will:
1. Keep `bucket1` (index 0)
2. Recreate `bucket3` as index 1 (was index 2)
3. Destroy old index 2

### Solution: Use for_each Instead
For_each doesn't have this problem - it uses keys instead of indices.

## 🎓 When to Use

### ✅ Good Use Cases:
- List won't change often
- Order doesn't matter if items are removed
- Simple iteration over fixed lists
- Creating users, groups, or identities

### ❌ Avoid When:
- List items might be added/removed from the middle
- You need stable resource addressing
- Resources have different configurations
- **→ Use `for_each` instead**

## 🔄 Migrating to for_each

If you need to convert this to for_each later:
```hcl
# Instead of count
resource "aws_s3_bucket" "buckets" {
  count  = length(var.bucket_configs)
  bucket = var.bucket_configs[count.index]
}

# Use for_each with toset()
resource "aws_s3_bucket" "buckets" {
  for_each = toset(var.bucket_configs)
  bucket   = each.value
}
```

## 💭 Comparison: Count vs For_Each

| Feature | Count | For_Each |
|:--------|:------|:---------|
| Indexing | Numeric (0, 1, 2) | By key |
| Stability | Changes on reorder | Stable keys |
| Removal | Re-indexes | No re-indexing |
| Best for | Fixed lists | Dynamic sets/maps |
