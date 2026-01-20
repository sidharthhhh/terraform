variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)"
  type        = string
}

variable "instance_count" {
  description = "Number of instances to deploy"
  type        = number
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
}

variable "allowed_ips" {
  description = "List of allowed IP addresses"
  type        = list(string)
}

variable "resource_tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
}

variable "user_roles" {
  description = "Set of user roles (guarantees uniqueness)"
  type        = set(string)
}

variable "database_config" {
  description = "Configuration object for the database"
  type = object({
    name    = string
    port    = number
    storage = number
  })
}

variable "subnet_cidrs" {
  description = "Tuple of exactly 3 subnet CIDRs"
  type        = tuple([string, string, string])
}
