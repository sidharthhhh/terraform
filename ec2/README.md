# Terraform EC2 Instance Configuration

This Terraform configuration creates a single EC2 instance on AWS with a security group and optional Elastic IP.

## Features

- ✅ EC2 instance with customizable instance type
- ✅ Automatic AMI selection (latest Ubuntu 22.04 LTS) or custom AMI
- ✅ Security group with SSH, HTTP, and HTTPS access
- ✅ Optional Elastic IP allocation
- ✅ Encrypted root volume (GP3)
- ✅ IMDSv2 enforced for enhanced security
- ✅ Customizable user data script
- ✅ Default tags for resource management

## Prerequisites

Before running this Terraform configuration, ensure you have:

1. **Terraform installed** (version >= 1.0)
   ```bash
   terraform version
   ```

2. **AWS CLI configured** with valid credentials
   ```bash
   aws configure
   ```
   You'll need:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (e.g., us-east-1)

3. **EC2 Key Pair** (Optional, but recommended for SSH access)
   - Create a key pair in the AWS EC2 console or via CLI:
     ```bash
     aws ec2 create-key-pair --key-name my-key-pair --query 'KeyMaterial' --output text > my-key-pair.pem
     chmod 400 my-key-pair.pem
     ```

## Quick Start

### 1. Initialize Terraform

```bash
cd ec2
terraform init
```

### 2. Create Configuration File

Copy the example file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your preferred values:

```hcl
aws_region    = "us-east-1"
instance_name = "my-web-server"
instance_type = "t2.micro"
key_name      = "my-key-pair"  # Your SSH key pair name
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted to create the resources.

### 5. Get Outputs

After successful creation, Terraform will display outputs:

```bash
terraform output
```

Example outputs:
- `instance_id`: The EC2 instance ID
- `instance_public_ip`: Public IP address
- `ssh_command`: Ready-to-use SSH command

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region | `us-east-1` | No |
| `environment` | Environment name | `dev` | No |
| `instance_name` | Name tag for instance | `my-ec2-instance` | No |
| `instance_type` | EC2 instance type | `t2.micro` | No |
| `ami_id` | Custom AMI ID | Auto (Ubuntu 22.04 LTS) | No |
| `key_name` | SSH key pair name | `""` | No* |
| `root_volume_size` | Root volume size (GB) | `10` | No |
| `allowed_ssh_cidr` | CIDR blocks for SSH | `["0.0.0.0/0"]` | No |
| `allocate_eip` | Allocate Elastic IP | `false` | No |
| `user_data_script` | Startup script | `""` | No |

\* Required for SSH access

## Example Use Cases

### Basic Instance for Testing

```hcl
instance_name = "test-instance"
instance_type = "t2.micro"
key_name      = "my-key"
root_volume_size = 10
```

### Production Instance with Elastic IP

```hcl
environment      = "prod"
instance_name    = "prod-app"
instance_type    = "t3.medium"
root_volume_size = 50
allocate_eip     = true
allowed_ssh_cidr = ["203.0.113.0/24"]  # Restrict to your office IP
```

## Connecting to Your Instance

After creation, use the SSH command from outputs:

```bash
# Get the SSH command
terraform output ssh_command

# Or manually connect
ssh -i ~/.ssh/my-key-pair.pem ubuntu@<instance_public_ip>
```

## Resource Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

## Security Best Practices

⚠️ **Important Security Considerations:**

1. **SSH Access**: The default configuration allows SSH from anywhere (`0.0.0.0/0`). In production, restrict this to your IP:
   ```hcl
   allowed_ssh_cidr = ["YOUR.IP.ADDRESS/32"]
   ```

2. **Key Management**: Never commit `.pem` files or `terraform.tfvars` with sensitive data to version control.

3. **Elastic IP**: Consider using Elastic IP for production to maintain a static IP address.

4. **IMDSv2**: This configuration enforces IMDSv2 (Instance Metadata Service v2) for enhanced security.

## Cost Estimation

- **t2.micro**: Free tier eligible (750 hours/month for 12 months)
- **GP3 Volume**: ~$0.08/GB-month (10GB = ~$0.80/month)
- **Elastic IP**: Free when attached to running instance, $0.005/hour when not attached
- **Data Transfer**: First 100GB/month free

## File Structure

```
ec2/
├── provider.tf               # Terraform and AWS provider configuration
├── main.tf                   # EC2 instance and security group resources
├── variables.tf              # Input variable definitions
├── outputs.tf                # Output value definitions
├── terraform.tfvars.example  # Example configuration values
└── README.md                 # This file
```

## Troubleshooting

### Issue: "InvalidKeyPair.NotFound"
**Solution**: Ensure the key pair exists in your AWS region:
```bash
aws ec2 describe-key-pairs --region us-east-1
```

### Issue: "UnauthorizedOperation"
**Solution**: Check your AWS credentials have EC2 permissions:
```bash
aws sts get-caller-identity
```

### Issue: Can't connect via SSH
**Solutions**:
1. Check security group allows SSH on port 22
2. Verify key permissions: `chmod 400 key.pem`
3. Use correct username (`ubuntu` for Ubuntu instances)
4. Check instance is in "running" state

## Next Steps

After setting up your EC2 instance, consider:
- Setting up CloudWatch monitoring
- Setting up CloudWatch monitoring
- Implementing Auto Scaling groups
- Adding Application Load Balancer
- Setting up VPC with private subnets

## 📸 Snapshot Management

### Create Backup
1. Edit `terraform.tfvars`:
   ```hcl
   create_snapshot = true
   ```
2. Run: `terraform apply`
3. **Important**: Set `create_snapshot = false` after creation.

### Restore from Backup
1. Edit `terraform.tfvars`:
   ```hcl
   restore_snapshot_id = "snap-xxxxxxxx"
   ```
2. Run: `terraform apply`

## Support

For issues or questions:
- Terraform Documentation: https://www.terraform.io/docs
- AWS EC2 Documentation: https://docs.aws.amazon.com/ec2
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws

---

**Created with Terraform** ❤️
