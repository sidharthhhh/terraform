# Lifecycle: ignore_changes Example

## 📚 What This Demonstrates
- Using `ignore_changes` to prevent Terraform from reverting external changes
- Managing resources that are modified by other systems
- Handling auto-scaling, CI/CD deployments, and secret rotation
- Understanding configuration drift
- Best practices and anti-patterns

## 🎯 What is ignore_changes?

`ignore_changes` tells Terraform to ignore changes to specific attributes, even if the actual value differs from your configuration.

### Normal Behavior (WITHOUT ignore_changes):
```
Your Terraform: desired_capacity = 3
AWS Current:    desired_capacity = 7 (scaled up by auto-scaling)

terraform apply
→ Changes desired_capacity back to 3 ❌
→ Undoes auto-scaling! Bad!
```

### With ignore_changes:
```
Your Terraform: desired_capacity = 3 (initial value)
AWS Current:    desired_capacity = 7 (scaled by auto-scaling)

terraform apply  
→ Ignores the difference ✅
→ Leaves it at 7! Good!
```

## 💡 Why is This Needed?

### Problem: Terraform vs External Systems

Many AWS resources are modified by external systems:
- **Auto Scaling** changes instance counts
- **CI/CD pipelines** deploy new code
- **Secrets Manager** rotates passwords
- **Monitoring tools** add tags
- **AWS** auto-upgrades minor versions
- **Ops teams** add temporary debugging rules

Without `ignore_changes`, Terraform fights these systems!

## 🚀 How to Use

### Deploy:
```bash
terraform init
terraform apply
```

### Simulate external changes:
```bash
# Scenario 1: Auto Scaling changes desired capacity
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name app-asg \
  --desired-capacity 5

# Check Terraform's reaction
terraform plan
# With ignore_changes: No changes! ✅
# Without ignore_changes: Wants to change back to 3 ❌
```

### Check for drift:
```bash
# See what has drifted
terraform plan -refresh-only

# View current actual state
terraform show
```

## 📊 Common Use Cases

### 1. Auto Scaling Group desired_capacity
```hcl
resource "aws_autoscaling_group" "app" {
  desired_capacity = 3  # Initial value only
  
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
```
** Why**: ASG scales based on metrics. Terraform shouldn't reset it.

### 2. EC2 Instance Tags (Added by External Tools)
```hcl
resource "aws_instance" "web" {
  tags = {
    Name = "Web Server"
  }
  
  lifecycle {
    ignore_changes = [
      tags["SSMManaged"],
      tags["BackupPolicy"]
    ]
  }
}
```
**Why**: AWS Systems Manager, AWS Backup, and monitoring tools add tags.

### 3. Lambda Function Code (Deployed via CI/CD)
```hcl
resource "aws_lambda_function" "app" {
  filename = "initial_code.zip"
  
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash
    ]
  }
}
```
**Why**: CI/CD pipeline deploys new code. Terraform manages infrastructure, not code.

### 4. RDS Password (Rotated by Secrets Manager)
```hcl
resource "aws_db_instance" "db" {
  password = var.initial_password
  
  lifecycle {
    ignore_changes = [password]
  }
}
```
**Why**: AWS Secrets Manager rotates passwords automatically.

### 5. Security Group Rules (Temporary Debugging)
```hcl
resource "aws_security_group" "app" {
  # Base rules...
  
  lifecycle {
    ignore_changes = [ingress, egress]
  }
}
```
**Why**: Ops team temporarily adds rules for troubleshooting.

### 6. RDS Engine Version (Auto Minor Upgrades)
```hcl
resource "aws_db_instance" "db" {
  engine_version          = "14.7"
  auto_minor_version_upgrade = true
  
  lifecycle {
    ignore_changes = [engine_version]
  }
}
```
**Why**: AWS automatically upgrades to 14.8, 14.9, etc.

## 🎨 Syntax and Patterns

### Ignore Single Attribute:
```hcl
lifecycle {
  ignore_changes = [desired_capacity]
}
```

### Ignore Multiple Attributes:
```hcl
lifecycle {
  ignore_changes = [
    desired_capacity,
    load_balancers,
    target_group_arns
  ]
}
```

### Ignore Specific Map/Object Keys:
```hcl
lifecycle {
  ignore_changes = [
    tags["SSMManaged"],
    tags["BackupPolicy"]
  ]
}
```

### Ignore Nested Attributes:
```hcl
lifecycle {
  ignore_changes = [
    environment[0].variables["DEBUG_MODE"]
  ]
}
```

### Ignore ALL Attributes (use carefully!):
```hcl
lifecycle {
  ignore_changes = all
}
```
**⚠️ Warning**: Terraform won't manage ANY changes!

## ⚠️ Important Considerations

### Configuration Drift

With `ignore_changes`, Terraform config != AWS reality:

```
Terraform says:  desired_capacity = 3
AWS reality:     desired_capacity = 7
```

This is **configuration drift**. It's intentional but can be confusing!

### Managing Drift:

1. **Monitor drift** with external tools
2. **Document** why attributes are ignored
3. **Update Terraform config** periodically to match reality
4. **Use `terraform plan -refresh-only`** to see drift

### Removing ignore_changes:

```bash
# 1. Remove the ignore_changes block
lifecycle {
  # ignore_changes = [desired_capacity]  # Commented out
}

# 2. Plan shows Terraform wants to change reality to match code
terraform plan

# 3. Decide:
#    - Update code to match reality
#    - OR apply to change reality to match code

# 4. Apply or update config
terraform apply
# OR
# Update desired_capacity = 7 in code
```

## 📈 Best Practices

### 1. Be Specific:
```hcl
# ✅ Good - specific attributes
lifecycle {
  ignore_changes = [desired_capacity, load_balancers]
}

# ❌ Bad - ignores everything!
lifecycle {
  ignore_changes = all
}
```

### 2. Document Why:
```hcl
lifecycle {
  ignore_changes = [password]
}
# Ignored because: Secrets Manager rotates password daily
# Owner: Security Team
# Review: Annually
```

### 3. Limit Scope:
```hcl
# ✅ Good - ignore specific tags
lifecycle {
  ignore_changes = [tags["SSMManaged"]]
}

# ❌ Bad - ignore all tags
lifecycle {
  ignore_changes = [tags]
}
```

### 4. Only for External Systems:
```hcl
# ✅ Good use case
lifecycle {
  ignore_changes = [desired_capacity]  # Auto Scaling manages this
}

# ❌ Bad use case
lifecycle {
  ignore_changes = [instance_type]  # You should manage this!
}
```

### 5. Periodic Reviews:
- Review ignored attributes quarterly
- Check if ignore_changes is still needed
- Update Terraform config to match reality
- Remove ignore_changes if external management stopped

## 🔍 AntiPatterns to Avoid

### ❌ Anti-Pattern 1: Hide Configuration Issues
```hcl
# Wrong! Fixing by ignoring instead of solving
resource "aws_instance" "broken" {
  ami = "ami-wrong"  # Wrong AMI
  
  lifecycle {
    ignore_changes = [ami]  # Don't do this!
  }
}
```

### ❌ Anti-Pattern 2: Ignore Everything
```hcl
# Wrong! Terraform not managing anything
lifecycle {
  ignore_changes = all
}
```

### ❌ Anti-Pattern 3: Work Around Terraform Bugs
```hcl
# Wrong! Fix Terraform code instead
lifecycle {
  ignore_changes = [some_attribute]  # Because Terraform keeps changing it
}
```

### ❌ Anti-Pattern 4: Band-Aid for Poor Organization
```hcl
# Wrong! Separate responsibilities properly
lifecycle {
  ignore_changes = [vpc_security_group_ids]  # Because another team manages this
}
# Better: Split resources, use modules, or data sources
```

## 🎓 Real-World Scenarios

### Scenario 1: Kubernetes Node Group
```hcl
resource "aws_eks_node_group" "app" {
  scaling_config {
    desired_size = 3
    min_size     = 2
    max_size     = 10
  }
  
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
# Cluster Autoscaler manages desired_size
```

### Scenario 2: Blue-Green Deployments
```hcl
resource "aws_lb_target_group" "app" {
  # ...
  
  lifecycle {
    ignore_changes = [
      load_balancing_algorithm_type  # Changed during blue-green swap
    ]
  }
}
```

### Scenario 3: Scheduled Auto Scaling
```hcl
resource "aws_autoscaling_group" "batch" {
  desired_capacity = 0  # Default: no instances
  
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
# CloudWatch Events scales this on schedule
```

## 🧪 Testing ignore_changes

### Test 1: Verify It's Ignored
```bash
# 1. Apply initial config
terraform apply

# 2. Change something in AWS console
# e.g., change desired_capacity from 3 to 5

# 3. Run plan
terraform plan

# Expected: No changes (because ignored) ✅
```

### Test 2: Remove Ignore and See Difference
```bash
# 1. Comment out ignore_changes
# 2. Plan
terraform plan

# Expected: Wants to change back to 3
# This confirms ignore_changes was working
```

### Test 3: Use refresh-only
```bash
terraform plan -refresh-only

# Shows drift but doesn't generate a plan to fix it
```

## 📖 Summary

### When to Use ignore_changes:
✅ External systems modify the resource  
✅ Auto Scaling changes capacity  
✅ CI/CD deploys code  
✅ Secrets rotation  
✅ Auto-upgrades  
✅ Operational tags

### When NOT to Use:
❌ Hiding configuration errors  
❌ Working around Terraform bugs  
❌ Things Terraform should manage  
❌ As a permanent band-aid  
❌ Everything (`all`)

### Remember:
1. **Be specific** - only ignore what's necessary
2. **Document** - explain why it's ignored
3. **Review** - periodically check if still needed
4. **Monitor drift** - use external tools
5. **Update config** - sync with reality periodically

**ignore_changes is powerful but creates drift. Use wisely! 🎯**
