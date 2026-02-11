# Depends_On Multiple Dependencies Example

## 📚 What This Demonstrates
- Managing multiple explicit dependencies
- Complex dependency chains
- IAM policy attachment dependencies
- VPC resource dependencies
- Cross-service dependencies (Lambda + SNS)
- Real-world Lambda function deployment

## 🎯 Why Multiple depends_on?

### The Lambda Dependency Problem:

A Lambda function needs MANY things to be ready:
1. **IAM Role** ✅ (implicit - we reference it)
2. **IAM Policies ATTACHED** ⚠️ (needs depends_on!)
3. **CloudWatch Log Group** ⚠️ (needs depends_on!)
4. **VPC/Subnet/SG configured** ⚠️ (needs depends_on!)

### Without depends_on:
```
❌ Lambda creates → Tries to assume role → Policies not attached yet → FAILS
❌ Lambda creates → Tries to write logs → Log group doesn't exist → Uses wrong permissions
❌ Lambda creates → Tries to join VPC → VPC not ready → FAILS
```

### With depends_on:
```
✅ All prerequisites ready → Lambda creates → Everything works!
```

## 🏗️ Dependency Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    IAM Foundation                        │
│  ┌──────────────┐                                       │
│  │  IAM Role    │                                       │
│  └──────┬───────┘                                       │
│         │                                               │
│    ┌────┴────┬───────────────────┐                     │
│    │         │                   │                     │
│    ▼         ▼                   ▼                     │
│  Policy   Policy              Other                    │
│  Basic     S3                Resources                 │
└────┬────────┬─────────────────────┬────────────────────┘
     │        │                     │
     │        │    ┌────────────────┼──────────┐
     │        │    │                │          │
     │        │    │   ┌────────────▼───┐  ┌──▼──────┐
     │        │    │   │  Log Group     │  │   VPC   │
     │        │    │   └────────────────┘  │Resources│
     │        │    │                       └─────────┘
     │        │    │                            │
     └────────┴────┴────────────────────────────┘
                   │
                   ▼
          ┌────────────────┐
          │ Lambda Function│
          └────────┬───────┘
                   │
     ┌─────────────┴──────────┐
     │                        │
     ▼                        ▼
┌─────────┐            ┌──────────────┐
│   SNS   │            │   Lambda     │
│  Topic  │────────────│  Permission  │
└─────────┘            └──────────────┘
```

## 🚀 How to Use

### Note: This example uses bash for the Lambda package creation
On Windows, you'll need:
- Git Bash
- WSL
- Or manually create the Lambda zip file

### Manual Lambda Package Creation (Windows):
1. Create a folder `lambda_temp`
2. Create `index.js` with:
   ```javascript
   exports.handler = async (event) => {
     return {
       statusCode: 200,
       body: JSON.stringify('Hello from Lambda!')
     };
   };
   ```
3. Zip the file as `lambda_function.zip`
4. Place in this directory

### Deploy:
```bash
terraform init
terraform plan  # See the dependency order
terraform apply
```

### Test the Lambda:
```bash
aws lambda invoke \
  --function-name demo-function \
  --payload '{}' \
  response.json

cat response.json
```

### View dependencies:
```bash
terraform output dependency_graph
terraform output why_depends_on_needed
```

## 📊 What Gets Created

1. **IAM Role** + 2 Policy Attachments
2. **CloudWatch Log Group** (/aws/lambda/demo-function)
3. **VPC** (10.0.0.0/16) + Subnet + Security Group
4. **S3 Bucket** (for Lambda deployments)
5. **Lambda Function** (depends on all above)
6. **SNS Topic** (for alerts)
7. **Lambda Permission** (depends on Lambda + SNS)

## 💡 Key Takeaways

### Multiple Dependencies:
```hcl
depends_on = [
  resource1,
  resource2,
  resource3
]
```

### Why Each Dependency:

1. **IAM Policy Attachments**:
   ```hcl
   depends_on = [
     aws_iam_role_policy_attachment.lambda_basic,
     aws_iam_role_policy_attachment.lambda_s3,
   ]
   ```
   - Role ARN is referenced (implicit dependency)
   - But policies might not be attached yet!
   - Lambda will fail to execute without policies

2. **CloudWatch Log Group**:
   ```hcl
   depends_on = [
     aws_cloudwatch_log_group.lambda_logs
   ]
   ```
   - If Lambda creates the log group, it gets wrong permissions
   - Better to create it first with proper retention

3. **VPC Resources**:
   ```hcl
   depends_on = [
     aws_vpc.lambda_vpc,
     aws_subnet.lambda_subnet,
     aws_security_group.lambda_sg
   ]
   ```
   - VPC configuration must be fully complete
   - Subnet must be available
   - Security group must exist

## ⚠️ Common Issues

### Issue 1: Lambda  Fails on First Apply
**Symptom**: Lambda creates but can't execute
**Cause**: IAM policies not attached yet
**Fix**: Add depends_on for policy attachments

### Issue 2: Log Permissions Wrong
**Symptom**: Lambda can't write logs
**Cause**: Lambda auto-created log group with wrong permissions
**Fix**: Pre-create log group with depends_on

### Issue 3: VPC Configuration Fails
**Symptom**: Lambda can't connect to VPC
**Cause**: VPC resources not fully configured
**Fix**: Add all VPC resources to depends_on

## 🎓 Real-World Scenarios

### Scenario 1: Multi-Service Application
```hcl
resource "aws_ecs_service" "app" {
  # Needs:
  # - Load balancer fully configured
  # - Target group created
  # - IAM roles attached
  # - Service discovery ready
  depends_on = [
    aws_lb_listener.app,
    aws_lb_target_group.app,
    aws_iam_role_policy_attachment.ecs_task,
    aws_service_discovery_service.app
  ]
}
```

### Scenario 2: Database with Read Replicas
```hcl
resource "aws_db_instance" "replica" {
  replicate_source_db = aws_db_instance.primary.id
  
  # Replica needs:
  # - Primary to be fully available
  # - Backup window configured
  # - Parameter group ready
  depends_on = [
    aws_db_instance.primary,
    aws_db_parameter_group.replica
  ]
}
```

### Scenario 3: Kubernetes Cluster
```hcl
resource "kubernetes_deployment" "app" {
  # Needs:
  # - Cluster fully initialized
  # - Node group available
  # - ConfigMaps/Secrets created
  depends_on = [
    aws_eks_cluster.cluster,
    aws_eks_node_group.nodes,
    kubernetes_config_map.app_config
  ]
}
```

## 📈 Best Practices

1. **List All Hidden Dependencies**:
   - IAM policy attachments (not just roles)
   - Resource configurations (not just resource creation)
   - Cross-service prerequisites

2. **Document Each Dependency**:
   ```hcl
   depends_on = [
     aws_iam_role_policy_attachment.policy,  # Required: Lambda needs S3 access
     aws_cloudwatch_log_group.logs,          # Required: Pre-create for correct permissions
   ]
   ```

3. **Test Without depends_on**:
   - Comment out depends_on
   - Run terraform apply
   - See what fails
   - This confirms the dependency is needed!

4. **Use Terraform Graph**:
   ```bash
   terraform graph | dot -Tpng > dependencies.png
   ```

5. **Minimize Use**:
   - Only use when truly needed
   - Prefer implicit dependencies (references)
   - Too many depends_on = slow applies

## 🔍 Debugging

### Check if Dependencies Are Needed:
```bash
# 1. Remove depends_on
# 2. Destroy resources
terraform destroy

# 3. Apply without depends_on
terraform apply
# Watch for failures - they indicate real dependencies

# 4. Add back only needed dependencies
```

### View Creation Order:
```bash
terraform plan -out=plan.out
terraform show -json plan.out | jq '.resource_changes[] | {address, change: .change.actions}'
```

## 🎯 When to Use Multiple depends_on

✅ **Use when**:
- Service needs multiple prerequisites fully configured
- Hidden dependencies not expressed in arguments
- Order matters for correctness (not just convenience)

❌ **Don't use when**:
- Dependencies are in resource arguments (Terraform handles it)
- "Just to be safe" mentality
- Can be expressed with references instead
