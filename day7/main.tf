resource "local_file" "config_dump" {
  filename = "${path.module}/config_dump.txt"
  content  = <<EOT
Project: ${var.project_name}
Environment: ${var.environment}
Instance Count: ${var.instance_count}
Monitoring Enabled: ${var.enable_monitoring}

Allowed IPs:
%{for ip in var.allowed_ips~}
- ${ip}
%{endfor~}

Tags:
%{for key, value in var.resource_tags~}
${key}: ${value}
%{endfor~}

User Roles (Set - Order undefined):
%{for role in var.user_roles~}
- ${role}
%{endfor~}

Database Config:
Name: ${var.database_config.name}
Port: ${var.database_config.port}
Storage: ${var.database_config.storage}GB

Subnets (Tuple):
1. ${var.subnet_cidrs[0]}
2. ${var.subnet_cidrs[1]}
3. ${var.subnet_cidrs[2]}
EOT
}
