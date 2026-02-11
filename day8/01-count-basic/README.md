# Count Basic Example

## 📚 What This Demonstrates
- Basic usage of the `count` meta-argument
- Creating multiple identical resources
- Using `count.index` for uniqueness
- Referencing count-based resources with `[index]` notation
- Using splat expression `[*]` to get all instances

## 🎯 Key Concepts

### Count Meta-Argument
```hcl
resource "aws_s3_bucket" "example" {
  count = 3  # Creates 3 instances
  
  bucket = "bucket-${count.index}"  # count.index: 0, 1, 2
}
```

### Referencing Count Resources
```hcl
# Single instance
aws_s3_bucket.example[0]  # First bucket

# All instances (splat expression)
aws_s3_bucket.example[*].bucket  # List of all bucket names

# Specific index
aws_s3_bucket.example[1]  # Second bucket
```

## 🚀 How to Use

1. **Initialize:**
   ```bash
   terraform init
   ```

2. **Plan:**
   ```bash
   terraform plan
   ```

3. **Apply:**
   ```bash
   terraform apply
   ```

4. **Check outputs:**
   ```bash
   terraform output
   ```

5. **Cleanup:**
   ```bash
   terraform destroy
   ```

## 📊 What Gets Created
- 3 S3 buckets with names: `my-terraform-bucket-0-xxx`, `my-terraform-bucket-1-xxx`, `my-terraform-bucket-2-xxx`
- Versioning enabled on all 3 buckets
- Each bucket tagged with its index

## 💡 Key Takeaways
- `count` creates numbered instances starting from 0
- Use `count.index` to differentiate resources
- Access instances using array notation: `resource[index]`
- Use splat `[*]` to get all instances
- Best for creating identical resources

## ⚠️ Important Notes
- If you change count from 3 to 2, the last bucket (index 2) will be destroyed
- Removing items from the middle causes re-indexing (use `for_each` to avoid this)
- Count must be a whole number known before apply
