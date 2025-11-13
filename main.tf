# --- 1. NETWORKING ---

# Get available AZs in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# Create the custom VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "sidharth_vpc"
  }
}

# Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "sidharth-igw"
  }
}

# Create public subnets (one in each AZ for high availability)
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Instances in this subnet get a public IP

  tags = {
    Name = "sidharth-public-subnet-${count.index + 1}"
  }
}

# Create a public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "sidharth-public-rt"
  }
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- 2. SECURITY GROUPS ---

# Security Group for your SSH access
resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh-from-my-ip"
  description = "Allow SSH inbound traffic from my IP"
  vpc_id      = aws_vpc.main.id

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
    Name = "allow-ssh-from-my-ip"
  }
}

# Security Group for the Load Balancer (allows public HTTP)
resource "aws_security_group" "lb_http" {
  name        = "allow-public-http"
  description = "Allow public HTTP traffic to Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb-allow-http"
  }
}

# Security Group for the EC2 Instances
resource "aws_security_group" "instance_http" {
  name        = "allow-http-from-lb"
  description = "Allow HTTP from LB and SSH from my-ip"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP (port 80) only from the Load Balancer's security group
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_http.id]
  }

  # Allow SSH (port 22) only from the SSH security group
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_ssh.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance-allow-http-ssh"
  }
}

# --- 3. CLOUDWATCH IAM ROLE ---

# IAM Role that allows EC2 instances to send logs to CloudWatch
resource "aws_iam_role" "ec2_cloudwatch_agent_role" {
  name = "EC2CloudWatchAgentRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AWS-managed policy for the CloudWatch agent
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attach" {
  role       = aws_iam_role.ec2_cloudwatch_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create an Instance Profile to attach the role to EC2 instances
resource "aws_iam_instance_profile" "ec2_cloudwatch_agent_profile" {
  name = "EC2CloudWatchAgentProfile"
  role = aws_iam_role.ec2_cloudwatch_agent_role.name
}

# --- 4. EC2 INSTANCES ---

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

# User data script to install Nginx and CloudWatch Agent
data "template_file" "user_data" {
  template = <<-EOF
#!/bin/bash
# Update and install Nginx
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y
sudo systemctl start nginx
sudo systemctl enable nginx
echo "<h1>Hello from $(hostname -f) in AZ $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</h1>" | sudo tee /usr/share/nginx/html/index.html

# Install CloudWatch Agent
sudo yum install amazon-cloudwatch-agent -y

# Create CloudWatch Agent config file for Nginx
cat <<'EOT' | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/config.json
{
  "agent": {
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "nginx-access-log",
            "log_stream_name": "{instance_id}/access"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "nginx-error-log",
            "log_stream_name": "{instance_id}/error"
          }
        ]
      }
    }
  }
}
EOT

# Start the CloudWatch Agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-control -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json -s
EOF
}

# Create 2 EC2 Instances
resource "aws_instance" "web_server" {
  count         = 2
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = aws_subnet.public[count.index].id
  
  # Attach both the HTTP/SSH group and the SSH-only group
  # Note: The 'instance_http' group ALREADY includes rules for 'allow_ssh'
  # We just need to add the one that allows SSH from our IP.
  vpc_security_group_ids = [
    aws_security_group.instance_http.id,
    aws_security_group.allow_ssh.id
  ]
  
  user_data = data.template_file.user_data.rendered
  
  # Attach the IAM role
  iam_instance_profile = aws_iam_instance_profile.ec2_cloudwatch_agent_profile.name

  tags = {
    Name = "sidharth-web-server-${count.index + 1}"
  }
}

# --- 5. LOAD BALANCER ---

# Create the Application Load Balancer
resource "aws_lb" "main" {
  name               = "sidharth-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_http.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  tags = {
    Name = "sidharth-lb"
  }
}

# Create the Target Group for the instances
resource "aws_lb_target_group" "main" {
  name     = "sidharth-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "sidharth-tg"
  }
}

# Attach the instances to the Target Group
resource "aws_lb_target_group_attachment" "web_server" {
  count            = 2
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web_server[count.index].id
  port             = 80
}

# Create the LB Listener (listens on port 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# --- 6. OUTPUTS ---

output "load_balancer_dns" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}