# Lifecycle: create_before_destroy Example

## 📚 What This Demonstrates
- Using `create_before_destroy` lifecycle rule
- Zero-downtime resource updates
- Common use cases (Launch Templates, Security Groups, Target Groups)
- Preventing service interruptions during infrastructure updates

## 🎯 What is create_before_destroy?

### Normal Resource Recreation:
```
1. Destroy old resource ❌ (DOWNTIME STARTS)
2. Create new resource  ✅ (DOWNTIME ENDS)
```

### With create_before_destroy:
```
1. Create new resource  ✅ (No downtime)
2. Update references    ✅ (Seamless transition)
3. Destroy old resource ✅ (Cleanup)
```

## 💡 Why is This Needed?

### Problem Without It:
```hcl
resource "aws_launch_template" "app" {
  name = "app-template"
  # ...
}

resource "aws_autoscaling_group" "app" {
  launch_template {
    id = aws_launch_template.app.id
  }
}
```

**What happens when launch template changes:**
1. Terraform destroys old template
2. ASG now references non-existent template ❌
3. ASG fails!
4. New template creation fails
5. **Everything breaks!**

### Solution With create_before_destroy:
```hcl
resource "aws_launch_template" "app" {
  name_prefix = "app-template-"  # Note: use prefix!
  
  lifecycle {
    create_before_destroy = true
  }
}
```

**What happens now:**
1. Terraform creates NEW template (app-template-abc123)
2. Updates ASG to use NEW template
3. Destroys OLD template (app-template-xyz789)
4. **Everything works! ✅**

## 🚀 How to Use

### Initial deployment:
```bash
terraform init
terraform apply
```

### Test create_before_destroy:
```bash
# Change the version to trigger recreation
terraform apply -var="app_version=v2.0"

# Watch the output carefully:
# You should see "+/~" not "-/+"
# This means create before destroy!
```

### Compare with destroy_create:
```bash
# 1. Comment out the lifecycle block
# 2. Run: terraform apply
# 3. See "-/+" (destroy first - causes downtime!)
```

## 📊 Resources Using create_before_destroy

### 1. Launch Template
**Why**: ASGs reference by ID. Destroying first breaks the reference.
```hcl
resource "aws_launch_template" "app" {
  name_prefix = "app-"  # Use prefix for unique names!
  
  lifecycle {
    create_before_destroy = true
  }
}
```

### 2. Security Group
**Why**: Instances attached to SG. Destroying first leaves instances unprotected.
```hcl
resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  
  lifecycle {
    create_before_destroy = true
  }
}
```

### 3. Target Group
**Why**: ALB routes traffic to TG. Destroying first stops traffic flow.
```hcl
resource "aws_lb_target_group" "app" {
  name_prefix = "app-"
  
  lifecycle {
    create_before_destroy = true
  }
}
```

## ⚠️ Important Requirements

### 1. Use `name_prefix` Instead of `name`:
```hcl
# ❌ Wrong - name conflicts during create_before_destroy
resource "aws_launch_template" "app" {
  name = "app-template"
  lifecycle {
    create_before_destroy = true
  }
}

# ✅ Correct - unique names with prefix
resource "aws_launch_template" "app" {
  name_prefix = "app-template-"
  lifecycle {
    create_before_destroy = true
  }
}
```

**Why**: During create_before_destroy, BOTH resources exist simultaneously.
Fixed names conflict. Prefixes allow unique names (app-template-abc, app-template-xyz).

### 2. Resources Must Support Replacement:
Not all resources can use create_before_destroy:
- ✅ Launch Templates (use prefix)
- ✅ Security Groups (use prefix)
- ✅ Target Groups (use prefix)
- ❌ IAM Roles with fixed names
- ❌ S3 Buckets (names are globally unique)

## 🎨 Real-World Scenarios

### Scenario 1: Blue-Green Deployment
```hcl
resource "aws_launch_template" "app" {
  name_prefix   = "app-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  min_size = 2
  max_size = 10
}
```

**Update Flow**:
1. Change `var.ami_id` to new AMI
2. Terraform creates new launch template
3. ASG starts launching instances with new template
4. Health checks pass
5. Old template destroyed
6. **Zero downtime!** ✅

### Scenario 2: Database Migration with RDS
```hcl
resource "aws_db_parameter_group" "app" {
  name_prefix = "app-pg-"
  family      = "postgres14"
  
  parameter {
    name  = "shared_buffers"
    value = var.shared_buffers
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "app" {
  parameter_group_name = aws_db_parameter_group.app.name
  # ...
}
```

### Scenario 3: ALB with Target Groups
```hcl
resource "aws_lb_target_group" "blue" {
  name_prefix = "blue-"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}
```

## 🔍 Terraform Plan Symbols

### Without create_before_destroy:
```
-/+ aws_launch_template.app must be replaced
```
Meaning: **Destroy**, then **Create** (❌ Downtime!)

### With create_before_destroy:
```
+/~ aws_launch_template.app must be replaced
```
Meaning: **Create**, then **Destroy** (✅ No downtime!)

## 📈 Best Practices

### 1. Always Use with Launch Resources:
```hcl
# Launch Templates
# Launch Configurations
# Auto Scaling Group launch_templates
lifecycle {
  create_before_destroy = true
}
```

### 2. Use name_prefix:
```hcl
resource "aws_security_group" "app" {
  name_prefix = "app-sg-"  # Not "name"
  lifecycle {
    create_before_destroy = true
  }
}
```

### 3. Combine with Other Lifecycle Rules:
```hcl
lifecycle {
  create_before_destroy = true
  ignore_changes = [
    tags["LastModified"]
  ]
}
```

### 4. Test Your Updates:
```bash
# Always check the plan
terraform plan

# Look for +/~ (create_before_destroy)
# vs -/+ (destroy_create)
```

##⚠️ Common Issues

### Issue 1: Name Conflicts
**Error**: `Error: resource already exists`
**Cause**: Using `name` instead of `name_prefix`
**Fix**: Change to `name_prefix`

### Issue 2: Dependency Conflicts
**Error**: `Error: cannot destroy resource, still in use`
**Cause**: Other resources depend on the resource being recreated
**Fix**: Add create_before_destroy to dependent resources too

### Issue 3: Resource Limits
**Error**: `Error: quota exceeded`
**Cause**: Creating new resource before destroying old one hits limits
**Fix**: Request quota increase or use different strategy

## 🎓 When to Use

✅ **Use create_before_destroy when:**
- Resource is referenced by other resources
- Downtime is unacceptable
- Blue-green deployment strategy
- Resources change frequently
- Zero-downtime requirement

❌ **Don't use when:**
- Resource name must be fixed (no prefix allowed)
- Resource is expensive (doubles cost temporarily)
- Dependencies prevent it
- Not needed (simple resources)

## 🧪 Testing

### Test 1: Verify Zero Downtime
```bash
# 1. Deploy initial version
terraform apply -var="app_version=v1.0"

# 2. In another terminal, watch resources
watch -n 1 'aws ec2 describe-launch-templates --query "LaunchTemplates[].[LaunchTemplateName,LatestVersionNumber]"'

# 3. Update version
terraform apply -var="app_version=v2.0"

# 4. Observe: New template appears BEFORE old one disappears
```

### Test 2: Compare With/Without
```bash
# Without create_before_destroy
# Comment out lifecycle block
terraform apply -var="app_version=v3.0"
# See: -/+ (destroy first)

# With create_before_destroy  
# Uncomment lifecycle block
terraform apply -var="app_version=v4.0"
# See: +/~ (create first)
```

## 📖 Summary

`create_before_destroy` is essential for:
- **Zero-downtime updates**
- **Blue-green deployments**
- **Maintaining service availability**
- **Preventing reference breaks**

Always use it with resources that:
- Are referenced by other resources
- Serve live traffic
- Cannot have downtime
- Support `name_prefix`
