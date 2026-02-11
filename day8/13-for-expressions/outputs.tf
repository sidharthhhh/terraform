# ============================================================================
# BASIC FOR EXPRESSIONS
# ============================================================================

# Example 1: Transform list to list
output "server_names_list" {
  description = "List of all server names"
  value       = [for k, v in var.servers : k]
}

# Example 2: Transform map to list
output "instance_ids_list" {
  description = "List of instance IDs"
  value       = [for k, instance in aws_instance.servers : instance.id]
}

# Example 3: Transform list to map
output "server_to_instance_type" {
  description = "Map of server name to instance type"
  value = {
    for k, v in var.servers : k => v.instance_type
  }
}

# Example 4: Transform map to map with different structure
output "server_details" {
  description = "Transformed server details"
  value = {
    for k, instance in aws_instance.servers : k => {
      id            = instance.id
      instance_type = instance.instance_type
      private_ip    = instance.private_ip
      public_ip     = instance.public_ip
    }
  }
}

# ============================================================================
# FILTERING WITH FOR EXPRESSIONS
# ============================================================================

# Example 5: Filter list - only production servers
output "production_servers" {
  description = "Only production environment servers"
  value = [
    for k, v in var.servers : k
    if v.environment == "production"
  ]
}

# Example 6: Filter map - only public instances
output "public_instances" {
  description = "Only servers that are public"
  value = {
    for k, v in var.servers : k => aws_instance.servers[k].public_ip
    if v.public
  }
}

# Example 7: Filter and transform - production instances with details
output "production_instance_details" {
  description = "Detailed info for production instances only"
  value = {
    for k, instance in aws_instance.servers : k => {
      id         = instance.id
      private_ip = instance.private_ip
      team       = var.servers[k].team
    }
    if var.servers[k].environment == "production"
  }
}

# ============================================================================
# GROUPING WITH FOR EXPRESSIONS
# ============================================================================

# Example 8: Group servers by environment
output "servers_by_environment" {
  description = "Servers grouped by environment"
  value = {
    for env in distinct([for k, v in var.servers : v.environment]) : env => [
      for k, v in var.servers : k
      if v.environment == env
    ]
  }
}

# Example 9: Group servers by team
output "servers_by_team" {
  description = "Servers grouped by team"
  value = {
    for team in distinct([for k, v in var.servers : v.team]) : team => [
      for k, v in var.servers : k
      if v.team == team
    ]
  }
}

# Example 10: Group instances by subnet type
output "instances_by_subnet_type" {
  description = "Instances grouped by public/private subnet"
  value = {
    public = [
      for k, v in var.servers : k
      if v.public
    ]
    private = [
      for k, v in var.servers : k
      if !v.public
    ]
  }
}

# ============================================================================
# AGGREGATIONS AND CALCULATIONS
# ============================================================================

# Example 11: Count servers by environment
output "server_count_by_environment" {
  description = "Count of servers in each environment"
  value = {
    for env in distinct([for k, v in var.servers : v.environment]) : env => length([
      for k, v in var.servers : k
      if v.environment == env
    ])
  }
}

# Example 12: Total storage by team
output "total_storage_by_team" {
  description = "Total storage (GB) allocated per team"
  value = {
    for team in distinct([for k, v in var.servers : v.team]) : team => sum([
      for k, v in var.servers : v.volume_size
      if v.team == team
    ])
  }
}

# Example 13: Average volume size by environment
output "avg_volume_size_by_environment" {
  description = "Average volume size per environment"
  value = {
    for env in distinct([for k, v in var.servers : v.environment]) : env => (
      sum([for k, v in var.servers : v.volume_size if v.environment == env]) /
      length([for k, v in var.servers : k if v.environment == env])
    )
  }
}

# ============================================================================
# COMPLEX TRANSFORMATIONS
# ============================================================================

# Example 14: Create DNS-style records
output "dns_records" {
  description = "DNS record format for servers"
  value = {
    for k, instance in aws_instance.servers : k => {
      A_record    = instance.private_ip
      public_A    = instance.public_ip != "" ? instance.public_ip : "none"
      hostname    = "${k}.internal.example.com"
      environment = var.servers[k].environment
    }
  }
}

# Example 15: Create inventory format
output "ansible_inventory" {
  description = "Ansible inventory format"
  value = {
    for env in distinct([for k, v in var.servers : v.environment]) : env => {
      hosts = {
        for k, instance in aws_instance.servers : k => {
          ansible_host = instance.private_ip
          ansible_user = "ec2-user"
        }
        if var.servers[k].environment == env
      }
    }
  }
}

# Example 16: S3 bucket URLs
output "bucket_urls" {
  description = "S3 bucket URLs"
  value = {
    for k, bucket in aws_s3_bucket.team_buckets : k => "https://${bucket.bucket}.s3.amazonaws.com"
  }
}

# ============================================================================
# CONDITIONAL TRANSFORMATIONS
# ============================================================================

# Example 17: Server status summary
output "server_status_summary" {
  description = "Summarized server status"
  value = {
    for k, instance in aws_instance.servers : k => {
      status = instance.instance_state
      type   = instance.instance_type
      cost_tier = (
        instance.instance_type == "t2.nano" ? "minimal" :
        instance.instance_type == "t2.micro" ? "low" :
        instance.instance_type == "t2.small" ? "medium" :
        instance.instance_type == "t2.medium" ? "high" :
        "unknown"
      )
    }
  }
}

# Example 18: Bucket security summary
output "bucket_security_summary" {
  description = "Security configuration of buckets"
  value = {
    for k, v in var.team_buckets : k => {
      bucket_name    = aws_s3_bucket.team_buckets[k].bucket
      versioning     = v.versioning ? "enabled" : "disabled"
      encryption     = v.encryption ? "enabled" : "disabled"
      security_score = (v.versioning && v.encryption) ? "high" : (v.versioning || v.encryption) ? "medium" : "low"
      recommendations = compact([
        !v.versioning ? "Enable versioning" : null,
        !v.encryption ? "Enable encryption" : null
      ])
    }
  }
}

# ============================================================================
# IAM USER TRANSFORMATIONS
# ============================================================================

# Example 19: Active users by role
output "active_users_by_role" {
  description = "Active IAM users grouped by role"
  value = {
    for role in distinct([for k, v in var.iam_users : v.role if v.active]) : role => [
      for k, v in var.iam_users : k
      if v.role == role && v.active
    ]
  }
}

# Example 20: User access matrix
output "user_access_matrix" {
  description = "Matrix showing user access levels"
  value = {
    for k, v in var.iam_users : k => {
      status = v.active ? "active" : "inactive"
      role   = v.role
      access_level = (
        v.role == "admin" ? "full" :
        v.role == "developer" ? "read-write" :
        v.role == "viewer" ? "read-only" :
        "none"
      )
      created_in_tf = contains(keys(aws_iam_user.users), k) ? "yes" : "no (filtered out)"
    }
  }
}

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

output "infrastructure_summary" {
  description = "Overall infrastructure summary"
  value = {
    total_servers = length(aws_instance.servers)
    total_buckets = length(aws_s3_bucket.team_buckets)
    total_users   = length(aws_iam_user.users)

    environments = distinct([for k, v in var.servers : v.environment])
    teams        = distinct([for k, v in var.servers : v.team])

    production_servers = length([for k, v in var.servers : k if v.environment == "production"])
    public_servers     = length([for k, v in var.servers : k if v.public])
    private_servers    = length([for k, v in var.servers : k if !v.public])

    total_storage_gb = sum([for k, v in var.servers : v.volume_size])

    instance_types = distinct([for k, v in var.servers : v.instance_type])
  }
}
