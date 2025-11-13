# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Define a Security Group to allow SSH from your IP
resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh-terraform"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # Uses the variable for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh-terraform"
  }
}

# The EC2 Instance Resource
resource "aws_instance" "my_server" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type # Uses the variable
  key_name      = var.key_name    # Uses the variable

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "Terraform-Server"
  }
}

# --- NEW: Elastic IP ---
resource "aws_eip" "my_eip" {
  domain = "vpc"

  tags = {
    Name = "Terraform-EIP"
  }
}

# --- NEW: EIP Association ---
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.my_server.id
  allocation_id = aws_eip.my_eip.id
}

# --- UPDATED: Output ---
output "instance_elastic_ip" {
  description = "Public Elastic IP address of the EC2 instance"
  value       = aws_eip.my_eip.public_ip
}