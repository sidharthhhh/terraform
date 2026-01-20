output "project_info" {
  value = "Project: ${var.project_name} (${var.environment})"
}

output "unique_roles" {
  description = "Notice duplicates are removed"
  value       = var.user_roles
}

output "db_connection" {
  value = "Connect to ${var.database_config.name} at port ${var.database_config.port}"
}
