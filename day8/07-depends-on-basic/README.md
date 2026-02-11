# Depends_On Basic Example

## 📚 What This Demonstrates
- Using `depends_on` for explicit dependency management
- Hidden dependencies that Terraform can't auto-detect
- Proper ordering for S3 website hosting setup
- When to use depends_on vs implicit dependencies

## 🎯 Key Concepts

### Implicit vs Explicit Dependencies

#### Implicit (Automatic):
```hcl
resource "aws_s3_bucket" "bucket" {
  bucket = "my-bucket"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id  # ← Terraform auto-detects dependency
}
```

#### Explicit (Manual with depends_on):
```hcl
resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.policy.json
  
  # Hidden dependency: PAB must be configured first
  depends_on = [
    aws_s3_bucket_public_access_block.pab
  ]
}
```

### Why Depends_On is Needed Here

1. **Public Access Block → Policy**
   - The bucket policy will fail if PAB blocks public access
   - Terraform doesn't know this from the resource references alone
   - We must explicitly order: PAB first, then policy

2. **Policy → Website Configuration**
   - Website hosting needs the policy to be active
   - This is a runtime dependency, not a reference dependency

3. **Website Config → Objects**
   - Objects should be uploaded after website is configured
   - Ensures proper configuration before content

## 🚀 How to Use

### Deploy:
```bash
terraform init
terraform apply
```

### Access the website:
```bash
# Get the URL
terraform output website_url

# Or visit directly (output will show the URL)
```

### Verify dependency order:
```bash
terraform output dependency_order
```

### Destroy:
```bash
terraform destroy
```

## 📊 Resource Creation Order

```
1. aws_s3_bucket.website
   ↓
2. aws_s3_bucket_public_access_block.website_pab
   ↓ (depends_on)
3. aws_s3_bucket_policy.website_policy
   ↓ (depends_on)
4. aws_s3_bucket_website_configuration.website
   ↓ (depends_on)
5. aws_s3_object.index
```

**Without depends_on**: These might create in parallel or wrong order, causing failures!

## 💡 Key Takeaways

### When to Use depends_on:
✅ Hidden runtime dependencies  
✅ IAM permissions must exist before use  
✅ Network configurations before apps  
✅ Prerequisites not expressed in resource arguments  

### When NOT to Use:
❌ Dependencies already in resource arguments (Terraform auto-detects)  
❌ "Just to be safe" (creates unnecessary ordering)  
❌ When a reference would work better  

## ⚠️ Important Notes

### Prefer Implicit Dependencies:
```hcl
# ✅ Better - implicit dependency
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
}

# ❌ Worse - unnecessary explicit dependency
resource "aws_s3_bucket_versioning" "versioning" {
  bucket     = "my-bucket"
  depends_on = [aws_s3_bucket.bucket]
}
```

### Depends_On Accepts a List:
```hcl
depends_on = [
  aws_s3_bucket.bucket,
  aws_iam_role.role,
  aws_vpc.vpc
]
```

### Dependencies Are Transitive:
If A depends on B, and B depends on C, then A implicitly depends on C.

## 🎓 Real-World Use Cases

1. **IAM Permissions**:
   ```hcl
   resource "aws_lambda_function" "function" {
     # ...
     depends_on = [aws_iam_role_policy_attachment.lambda_policy]
   }
   ```

2. **Network Setup**:
   ```hcl
   resource "aws_instance" "app" {
     # ...
     depends_on = [aws_nat_gateway.nat]
   }
   ```

3. **Database Initialization**:
   ```hcl
   resource "null_resource" "db_migration" {
     depends_on = [aws_db_instance.database]
   }
   ```

4. **Module Dependencies**:
   ```hcl
   module "application" {
     source = "./modules/app"
     depends_on = [module.networking]
   }
   ```

## 🐛 Debugging Dependencies

### View dependency graph:
```bash
terraform graph | dot -Tpng > graph.png
```

### See planned order:
```bash
terraform plan
# Look for "will be created" order
```

### Test without depends_on:
Comment out depends_on and see what fails!

## 📈 Best Practices

1. **Document Why**: Always comment why depends_on is needed
   ```hcl
   depends_on = [
     aws_s3_bucket_public_access_block.pab
   ]
   # Required: Policy attachment fails if PAB blocks public access
   ```

2. **Minimal Use**: Only use when absolutely necessary

3. **Implicit First**: Try to express dependency through references

4. **Test**: Verify the dependency is actually needed

## 🔍 Common Mistakes

### Mistake 1: Overuse
```hcl
# ❌ Unnecessary - bucket reference creates implicit dependency
resource "aws_s3_object" "file" {
  bucket     = aws_s3_bucket.bucket.id
  depends_on = [aws_s3_bucket.bucket]  # Redundant!
}
```

### Mistake 2: Circular Dependencies
```hcl
# ❌ Error: Cycle!
resource "a" {
  depends_on = [b]
}
resource "b" {
  depends_on = [a]
}
```

### Mistake 3: Wrong Syntax
```hcl
# ❌ Wrong
depends_on = aws_s3_bucket.bucket

# ✅ Correct (must be a list)
depends_on = [aws_s3_bucket.bucket]
```
