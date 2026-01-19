# Restore from Snapshot Configuration

# This resource creates a new AMI from the provided snapshot ID.
# It only runs if var.restore_snapshot_id has a value.
resource "aws_ami" "restored" {
  count = var.restore_snapshot_id != "" ? 1 : 0

  name                = "restored-started-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  description         = "Restored from snapshot ${var.restore_snapshot_id}"
  architecture        = "x86_64"
  root_device_name    = "/dev/sda1"
  virtualization_type = "hvm"
  ena_support         = true

  ebs_block_device {
    device_name           = "/dev/sda1"
    snapshot_id           = var.restore_snapshot_id
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
  }

  tags = {
    Name        = "Restored-AMI-${var.restore_snapshot_id}"
    Source      = "Terraform Restore"
    Environment = var.environment
  }
}
