# For_Each with Set Example

## 📚 What This Demonstrates
- Using `for_each` with a set of strings
- Understanding `each.key` and `each.value`
- Referencing for_each resources by key
- Chaining for_each across related resources
- Benefits over count for managing collections

## 🎯 Key Concepts

### For_Each with Set
```hcl
variable "names" {
  type    = set(string)
  default = ["alice", "bob", "charlie"]
}

resource "aws_iam_user" "users" {
  for_each = var.names
  name     = each.value  # For sets, each.key == each.value
}
```

### Referencing For_Each Resources
```hcl
# By specific key
aws_s3_bucket.buckets["application-logs"]

# All instances as map
aws_s3_bucket.buckets

# All values (convert map to list)
values(aws_s3_bucket.buckets)[*].bucket
```

### Chaining For_Each
```hcl
resource "aws_s3_bucket" "buckets" {
  for_each = var.bucket_names
  bucket   = each.key
}

# Use the bucket map in another resource
resource "aws_s3_bucket_versioning" "versioning" {
  for_each = aws_s3_bucket.buckets
  bucket   = each.value.id
}
```

## 🚀 How to Use

### Default configuration:
```bash
terraform init
terraform apply
```

### Custom bucket names:
```bash
terraform apply -var='bucket_names=["logs","data","archives"]'
```

### Custom users:
```bash
terraform apply -var='iam_user_names=["admin","user1","user2"]'
```

### Using terraform.tfvars:
```hcl
bucket_names = [
  "production-logs",
  "production-assets",
  "production-backups"
]

iam_user_names = [
  "prod-admin",
  "prod-developer",
  "prod-analyst"
]
```

## 📊 What Gets Created

### S3 Buckets (4 total)
- `application-logs-{account_id}` (with versioning & public access block)
- `user-uploads-{account_id}` (with versioning & public access block)
- `static-assets-{account_id}` (with versioning & public access block)
- `database-backups-{account_id}` (with versioning & public access block)

### IAM Users (3 total)
- `developer`
- `devops`
- `qa-engineer`

## 💡 Key Takeaways

### For Sets:
- `each.key` == `each.value` (both are the string element)
- Creates a map where keys are the set elements
- Access specific resource: `resource_type.name["key"]`
- Get all as list: `values(resource_type.name)[*].attribute`

### Advantages Over Count:
1. **Stable Addressing**: Resources identified by key, not index
2. **Safe Removal**: Removing "bob" doesn't affect "alice" or "charlie"
3. **Readable**: `aws_iam_user.users["alice"]` vs `aws_iam_user.users[0]`
4. **Flexible**: Add/remove items without affecting others

## 🔄 Adding/Removing Items

### Adding an Item:
```hcl
# Before
bucket_names = ["logs", "data", "backups"]

# After
bucket_names = ["logs", "data", "backups", "archives"]
```
**Result**: Only "archives" bucket is created. Others unchanged! ✅

### Removing an Item:
```hcl
# Before
bucket_names = ["logs", "data", "backups"]

# After
bucket_names = ["logs", "backups"]
```
**Result**: Only "data" bucket is destroyed. Others unchanged! ✅

### With Count (for comparison):
```hcl
# Before
bucket_configs = ["logs", "data", "backups"]  # indices: 0, 1, 2

# After
bucket_configs = ["logs", "backups"]  # indices: 0, 1
```
**Result**: "backups" is recreated as index 1 (was index 2) ❌

## ⚠️ Important Notes

### Sets vs Lists:
- Sets have no order and no duplicates
- Lists have order and can have duplicates
- For lists, convert to set: `for_each = toset(var.my_list)`

### Accessing Resources:
```hcl
# Correct
aws_s3_bucket.buckets["application-logs"]

# Incorrect (sets don't have numeric indices)
aws_s3_bucket.buckets[0]  # ❌ Error!
```

## 🎓 Real-World Use Cases
- Creating IAM users/groups/roles
- Provisioning S3 buckets for different purposes
- Setting up security groups for different services
- Creating DNS records
- Managing infrastructure for multiple environments

## 📈 Comparison: Count vs For_Each (Set)

| Feature | Count | For_Each (Set) |
|:--------|:------|:---------------|
| Indexing | Numeric (0, 1, 2) | By string key |
| Add item | Appends at end | Adds by key |
| Remove item | Shifts indices | Removes by key |
| Access | `resource[0]` | `resource["key"]` |
| Stability | ❌ Low | ✅ High |
| Readability | ⚠️ Medium | ✅ High |
| Best for | Fixed count | Dynamic collections |
