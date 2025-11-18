🚀 Serverless Static Website (Single-File Terraform)

This project deploys a production-ready, secure static website on AWS using Terraform.

Everything—the infrastructure logic, the security policies, and even the HTML website content—is contained in a single main.tf file. This makes it incredibly easy to share, version control, and deploy.

🏗️ Architecture

This project uses the S3 + CloudFront + OAI pattern, which is the industry standard for secure static hosting.

S3 Bucket (Private): Stores your website files. Public access is strictly blocked.

CloudFront (CDN): Distributes your content globally via HTTPS for high performance.

Origin Access Identity (OAI): A virtual security identity that allows CloudFront to fetch files from your private S3 bucket.

Traffic Flow:
User → CloudFront (HTTPS) → OAI Auth → S3 Bucket (Private)

📋 Prerequisites

Terraform (v1.0+)

AWS CLI installed and configured (aws configure)

⚡ Quick Start

1. Setup

Save the provided Terraform code into a file named main.tf.

2. Initialize

Download the required AWS providers:

terraform init


3. Deploy

Create the infrastructure:

terraform apply --auto-approve


Note: CloudFront distributions take 5-10 minutes to create. Terraform will pause and wait during this time.

4. Access

When the deployment finishes, Terraform will output your website URL:

Outputs:
website_url = "[https://d12345abcdef.cloudfront.net](https://d12345abcdef.cloudfront.net)"


Click the link to view your live site!

🛠️ How to Modify the Website

Since this is a single-file setup, the HTML is embedded directly in the Terraform code.

Open main.tf.

Locate the resource "aws_s3_object" "index_html" block.

Edit the HTML inside the content = <<EOF ... EOF section.

Run terraform apply to push your changes.

🧹 Cleanup

To remove all resources and stop any costs:

terraform destroy --auto-approve


📦 Resources Created

AWS S3 Bucket: Private object storage.

AWS S3 Bucket Policy: Restricts access to the OAI only.

AWS CloudFront Distribution: Global Content Delivery Network.

AWS CloudFront OAI: Security identity.