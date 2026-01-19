# Create snapshots directly with Terraform

# Variable to enable snapshot creation
variable "create_snapshot" {
  description = "Set to true to create a snapshot of the instance volume"
  type        = bool
  default     = false
}

variable "snapshot_description" {
  description = "Description for the snapshot"
  type        = string
  default     = "Terraform managed snapshot"
}

# Data source to get the instance's root volume
data "aws_ebs_volume" "instance_root" {
  count = var.create_snapshot ? 1 : 0

  most_recent = true

  filter {
    name   = "attachment.instance-id"
    values = [aws_instance.main.id]
  }

  filter {
    name   = "attachment.device"
    values = ["/dev/sda1", "/dev/xvda"]
  }

  depends_on = [aws_instance.main]
}

# Create snapshot resource
resource "aws_ebs_snapshot" "backup" {
  count = var.create_snapshot ? 1 : 0

  volume_id   = data.aws_ebs_volume.instance_root[0].id
  description = var.snapshot_description

  tags = {
    Name        = "${var.instance_name}-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
    Environment = var.environment
    CreatedBy   = "Terraform"
    InstanceId  = aws_instance.main.id
  }
}

# Output snapshot details
output "snapshot_id" {
  description = "ID of the created snapshot"
  value       = var.create_snapshot ? aws_ebs_snapshot.backup[0].id : null
}

output "snapshot_arn" {
  description = "ARN of the created snapshot"
  value       = var.create_snapshot ? aws_ebs_snapshot.backup[0].arn : null
}
