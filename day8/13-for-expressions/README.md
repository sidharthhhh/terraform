# For Expressions - Advanced Output Transformations

## 📚 What This Demonstrates
- Complete guide to Terraform for expressions
- Transforming lists and maps
- Filtering data
- Grouping and aggregations
- Complex multi-step transformations
- Real-world output formatting

## 🎯 What are For Expressions?

For expressions allow you to transform one collection type to another. They're similar to list comprehensions in Python or map/filter in JavaScript.

### Basic Syntax:

```hcl
# List → List
[for item in list : transform(item)]

# List → Map
{for item in list : item.key => item.value}

# Map → List
[for key, value in map : value]

# Map → Map
{for key, value in map : key => transform(value)}
```

## 💡 Core Patterns

### Pattern 1: List to List
```hcl
variable "names" {
  default = ["alice", "bob", "charlie"]
}

output "uppercase_names" {
  value = [for name in var.names : upper(name)]
}
# Result: ["ALICE", "BOB", "CHARLIE"]
```

### Pattern 2: List to Map
```hcl
variable "servers" {
  default = ["web-1", "web-2", "api-1"]
}

output "server_map" {
  value = {
    for server in var.servers : server => "${server}.example.com"
  }
}
# Result: {
#   "web-1" = "web-1.example.com"
#   "web-2" = "web-2.example.com"
#   "api-1" = "api-1.example.com"
# }
```

### Pattern 3: Map to List
```hcl
variable "instances" {
  default = {
    "web-1" = { ip = "10.0.1.10" }
    "web-2" = { ip = "10.0.1.11" }
  }
}

output "ip_list" {
  value = [for k, v in var.instances : v.ip]
}
# Result: ["10.0.1.10", "10.0.1.11"]
```

### Pattern 4: Map to Map
```hcl
variable "servers" {
  default = {
    "web" = { type = "t2.micro" }
    "db"  = { type = "t2.small" }
  }
}

output "transformed" {
  value = {
    for k, v in var.servers : k => upper(v.type)
  }
}
# Result: {
#   "web" = "T2.MICRO"
#   "db"  = "T2.SMALL"
# }
```

## 🔍 Filtering with For Expressions

### Filter with if Clause:
```hcl
variable "servers" {
  default = {
    "web-1" = { environment = "production" }
    "web-2" = { environment = "staging" }
    "api-1" = { environment = "production" }
  }
}

output "production_only" {
  value = [
    for k, v in var.servers : k
    if v.environment == "production"
  ]
}
# Result: ["web-1", "api-1"]
```

### Multiple Conditions:
```hcl
output "filtered" {
  value = [
    for k, v in var.servers : k
    if v.environment == "production" && v.public == true
  ]
}
```

## 🚀 How to Use This Example

### Deploy resources:
```bash
terraform init
terraform apply
```

### View specific outputs:
```bash
# Basic transformations
terraform output server_names_list
terraform output server_to_instance_type

# Filtering
terraform output production_servers
terraform output public_instances

# Grouping
terraform output servers_by_environment
terraform output servers_by_team

# Aggregations
terraform output total_storage_by_team
terraform output server_count_by_environment

# Complex transformations
terraform output dns_records
terraform output ansible_inventory

# Summary
terraform output infrastructure_summary
```

## 📊 20 For Expression Examples

### 1-4: Basic Transformations
- `server_names_list`: Extract keys as list
- `instance_ids_list`: Extract attribute values
- `server_to_instance_type`: Create simple map
- `server_details`: Create detailed map

### 5-7: Filtering
- `production_servers`: Filter by environment
- `public_instances`: Filter by boolean attribute
- `production_instance_details`: Filter and transform

### 8-10: Grouping
- `servers_by_environment`: Group by environment
- `servers_by_team`: Group by team
- `instances_by_subnet_type`: Group by public/private

### 11-13: Aggregations
- `server_count_by_environment`: Count items
- `total_storage_by_team`: Sum values
- `avg_volume_size_by_environment`: Calculate averages

### 14-16: Complex Transformations
- `dns_records`: Create DNS-style records
- `ansible_inventory`: Generate Ansible inventory
- `bucket_urls`: Generate URLs

### 17-18: Conditional Logic
- `server_status_summary`: Nested conditionals
- `bucket_security_summary`: Security scoring

### 19-20: IAM Examples
- `active_users_by_role`: User grouping
- `user_access_matrix`: Access level matrix

## 🎨 Advanced Techniques

### Technique 1: Nested For Expressions
```hcl
output "grouped_then_transformed" {
  value = {
    for env in distinct([for k, v in var.servers : v.environment]) : env => {
      servers = [for k, v in var.servers : k if v.environment == env]
      count   = length([for k, v in var.servers : k if v.environment == env])
    }
  }
}
```

### Technique 2: Flattening Nested Structures
```hcl
locals {
  # Flatten nested map of maps to single map
  flat_servers = merge([
    for stack_key, stack in var.stacks : {
      for server_key, server in stack.servers :
      "${stack_key}-${server_key}" => server
    }
  ]...)
}
```

### Technique 3: Using Functions
```hcl
output "sorted_servers" {
  value = [
    for k in sort(keys(var.servers)) : k
  ]
}

output "distinct_teams" {
  value = distinct([for k, v in var.servers : v.team])
}

output "total_storage" {
  value = sum([for k, v in var.servers : v.volume_size])
}
```

### Technique 4: Conditional Values
```hcl
output "server_tiers" {
  value = {
    for k, v in var.servers : k => (
      v.instance_type == "t2.nano" ? "free-tier" :
      v.instance_type == "t2.micro" ? "low-cost" :
      v.instance_type == "t2.small" ? "medium-cost" :
      "high-cost"
    )
  }
}
```

### Technique 5: String Interpolation
```hcl
output "server_fqdns" {
  value = {
    for k, v in var.servers : k => "${k}.${v.environment}.example.com"
  }
}
```

## 📈 Best Practices

### 1. Keep It Readable
```hcl
# ✅ Good - readable
output "production_servers" {
  value = [
    for k, v in var.servers : k
    if v.environment == "production"
  ]
}

# ❌ Bad - hard to read
output "production_servers" {
  value = [for k, v in var.servers : k if v.environment == "production"]
}
```

### 2. Use Locals for Complex Logic
```hcl
# ✅ Good - break down complexity
locals {
  production_servers = [
    for k, v in var.servers : k
    if v.environment == "production"
  ]
  
  production_ips = [
    for k in local.production_servers : aws_instance.servers[k].private_ip
  ]
}

output "production_ips" {
  value = local.production_ips
}
```

### 3. Document Complex Expressions
```hcl
output "dns_records" {
  description = "Generate DNS A records for all servers"
  # Format: { "server-name" => "ip.address" }
  value = {
    for k, instance in aws_instance.servers : k => instance.private_ip
  }
}
```

### 4. Avoid Deep Nesting
```hcl
# ❌ Bad - too nested
output "bad_example" {
  value = {
    for env in [...] : env => {
      for team in [...] : team => {
        for k, v in [...] : k => {
          # Too deep!
        }
      }
    }
  }
}

# ✅ Better - use locals to break it down
locals {
  servers_by_env = { for env in [...] : ... }
  servers_by_team = { for team in [...] : ... }
}
```

### 5. Use Type Constraints
```hcl
output "server_details" {
  description = "Detailed server information"
  
  value = {
    for k, instance in aws_instance.servers : k => {
      id            = instance.id            # string
      instance_type = instance.instance_type # string
      public        = var.servers[k].public  # bool
      volume_size   = var.servers[k].volume_size # number
    }
  }
}
```

## 🔍 Common Use Cases

### Use Case 1: Creating Ansible Inventory
```hcl
output "ansible_inventory" {
  value = {
    for env in distinct([for k, v in var.servers : v.environment]) : env => {
      hosts = {
        for k, instance in aws_instance.servers : k => {
          ansible_host = instance.private_ip
          ansible_user = "ec2-user"
          ansible_python_interpreter = "/usr/bin/python3"
        }
        if var.servers[k].environment == env
      }
    }
  }
}
```

### Use Case 2: Cost Calculation
```hcl
locals {
  instance_costs = {
    "t2.nano"   = 0.0058
    "t2.micro"  = 0.0116
    "t2.small"  = 0.023
    "t2.medium" = 0.046
  }
}

output "monthly_cost_by_team" {
  value = {
    for team in distinct([for k, v in var.servers : v.team]) : team => sum([
      for k, v in var.servers :
      local.instance_costs[v.instance_type] * 730 # hours/month
      if v.team == team
    ])
  }
}
```

### Use Case 3: Security Compliance Report
```hcl
output "security_compliance" {
  value = {
    for k, bucket in aws_s3_bucket.team_buckets : k => {
      versioning_compliant = var.team_buckets[k].versioning
      encryption_compliant = var.team_buckets[k].encryption
      fully_compliant     = var.team_buckets[k].versioning && var.team_buckets[k].encryption
      issues              = compact([
        !var.team_buckets[k].versioning ? "versioning-disabled" : null,
        !var.team_buckets[k].encryption ? "encryption-disabled" : null
      ])
    }
  }
}
```

### Use Case 4: Resource Tags Export
```hcl
output "resource_tags_csv" {
  value = join("\n", concat(
    ["Resource,Name,Environment,Team"],
    [
      for k, v in var.servers :
      "${k},${k},${v.environment},${v.team}"
    ]
  ))
}
```

## ⚠️ Common Mistakes

### Mistake 1: Wrong Syntax Order
```hcl
# ❌ Wrong
[for item in list if condition : transform]

# ✅ Correct
[for item in list : transform if condition]
```

### Mistake 2: Forgetting Brackets
```hcl
# ❌ Wrong - missing brackets around for expression
output "names" {
  value = for k in var.servers : k
}

# ✅ Correct
output "names" {
  value = [for k in var.servers : k]
}
```

### Mistake 3: Map Key Conflicts
```hcl
# ❌ Wrong - duplicate keys!
{
  for item in ["a", "a", "b"] : item => "value"
}
# Only keeps last "a"

# ✅ Better - ensure unique keys
{
  for idx, item in ["a", "a", "b"] : "${item}-${idx}" => "value"
}
```

### Mistake 4: Type Mismatch
```hcl
# ❌ Wrong - list where map expected
for_each = [for k in var.servers : k]

# ✅ Correct - convert to set
for_each = toset([for k in var.servers : k])
```

## 🧪 Testing For Expressions

### Test in Terraform Console:
```bash
terraform console

# Test expression interactively
> [for k, v in var.servers : k if v.environment == "production"]

# Test transformations
> {for k, v in var.servers : k => upper(v.team)}

# Test nested expressions
> {for env in distinct([for k, v in var.servers : v.environment]) : env => length([for k, v in var.servers : k if v.environment == env])}
```

## 📖 Summary

### For Expressions Enable:
✅ Data transformation and reshaping  
✅ Filtering collections  
✅ Grouping and aggregations  
✅ Dynamic output formatting  
✅ Complex data processing

### Key Points:
1. **Syntax**: `[for ...]` for lists, `{for ...}` for maps
2. **Filtering**: Add `if condition` at the end
3. **Keys**: In maps, use `key => value` syntax
4. **Nesting**: Can nest for expressions
5. **Functions**: Combine with `distinct()`, `sum()`, `length()`, etc.

### Remember:
- Keep expressions **readable**
- Use **locals** for complex logic
- **Document** non-obvious transformations
- **Test** in terraform console
- **Avoid** excessive nesting

**For expressions are powerful tools for data transformation! 🎯**
