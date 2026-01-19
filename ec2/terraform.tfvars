# AWS Configuration
aws_region  = "us-east-1"
environment = "dev"

# EC2 Instance Configuration
instance_name = "my-ec2-instance"
instance_type = "t2.micro" # Free tier eligible

# SSH Key (IMPORTANT: Create this key pair in AWS EC2 console first!)
key_name = "test" # Replace with your key pair name

# Storage
root_volume_size = 30 # GB (minimal SSD for basic instance)

# Security
allowed_ssh_cidr = ["0.0.0.0/0"] # WARNING: Allow SSH from anywhere (restrict this in production!)

# Optional: Allocate Elastic IP
allocate_eip = false

# Optional: Custom AMI ID (leave empty to use latest Ubuntu 22.04 LTS)
# ami_id = "ami-xxxxxxxxxxxxxxxxx"

# Snapshot Configuration
create_snapshot      = false # Set to true to create a snapshot
snapshot_description = "Backup of my-ec2-instance"


# Restore Configuration
# To restore, uncomment and paste your snapshot ID here:
#restore_snapshot_id = "snap-XXXXXXX"
