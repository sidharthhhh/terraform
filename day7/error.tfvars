project_name      = "TypeConstraintsDemo"
environment       = "dev"
instance_count    = "three" # Error: Should be a number
enable_monitoring = true

allowed_ips = [
  "192.168.1.1",
  "10.0.0.1",
  "172.16.0.1"
]

resource_tags = {
  "Dept" = "Engineering"
}

user_roles = ["Admin"]

database_config = {
  name    = "main-db"
  port    = 5432
  storage = 100
}

subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
