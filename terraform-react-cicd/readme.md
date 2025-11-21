# Serverless React CI/CD Pipeline on AWS via Terraform

This project provides a completely automated Infrastructure as Code (IaC) solution using **Terraform** to deploy a secure, scalable CI/CD pipeline for a React Single Page Application (SPA) hosted on AWS.

Any change pushed to the connected GitHub repository triggers AWS CodePipeline to automatically build the React application and deploy it to an S3 bucket served via CloudFront.

## 🏗️ Architecture

The following diagram illustrates the infrastructure provisioned by this Terraform project:

![AWS React CI/CD Architecture](./architecture.png)
*(Note: Save your generated architecture diagram as `architecture.png` in this folder)*

**Key Components:**
* **AWS CodePipeline:** Orchestrates the flow from change detection to deployment.
* **GitHub Connection (CodeStar):** Securely connects AWS to your source code.
* **AWS CodeBuild:** Two separate projects: one to compile the React app (`npm run build`) and another to invalidate the CloudFront cache.
* **Amazon S3:** Two buckets: one for hosting the frontend static files, and one for storing intermediate pipeline artifacts.
* **Amazon CloudFront:** Global CDN serving the application securely via HTTPS using Origin Access Control (OAC) to lock down the S3 bucket.

---

## ⚠️ Critical Prerequisites & Manual Steps

While Terraform automates 95% of the setup, **you must focus on these two manual steps before running Terraform**, otherwise deployment will fail.

### 1. The GitHub Handshake (Crucial)
Terraform cannot authorize access to your GitHub account on its own. You must create the connection placeholder in the AWS Console first.

1.  Log into your AWS Console (in the region you intend to deploy, e.g., `us-east-1`).
2.  Navigate to **Developer Tools** -> **Settings** -> **Connections**.
3.  Click **Create connection**.
4.  Select **GitHub**, name it (e.g., `my-react-repo-connection`), and click **Connect to GitHub**.
5.  Follow the pop-up prompts to authorize AWS to access your GitHub account. **Ensure you grant access to the specific repository you plan to use.**
6.  Once the status is **Available** (Green), copy the **Connection ARN**. You will need this for `terraform.tfvars`.

### 2. Unique Project Naming
S3 Bucket names must be globally unique across all AWS accounts worldwide.

* In `terraform.tfvars`, ensure your `project_name` variable is unique.
* *Bad:* `project_name = "react-cicd"` (Already taken)
* *Good:* `project_name = "sidharth-portfolio-2025"`

---

## 🛠️ Deployment Guide

Follow these steps in order to deploy the infrastructure.

### Prerequisites Tools
* AWS CLI (configured with admin credentials)
* Terraform v1.5+
* Git bash (if on Windows)

### Step 1: Backend Initialization
We use remote state storage (S3) and state locking (DynamoDB) for robust Terraform usage. Run the provided script to set this up one time.

```bash
# Make the script executable
chmod +x backend_setup.sh

# Run the script
./backend_setup.sh




Step 2: Configure Variables
Create a file named terraform.tfvars in the root directory and populate it with your specific details.

terraform.tfvars

aws_region              = "us-east-1"
# MUST be unique globally to avoid S3 conflicts
project_name            = "sidharth-portfolio-app-2025"
github_repo_owner       = "sidharthhhh"
github_repo_name        = "portfoliooooo"
github_branch           = "main"
# The ARN you copied in Manual Step 1 above
codestar_connection_arn = "arn:aws:codeconnections:us-east-1:123456789:connection/abcdef-1234-..."

Step 3: Deploy Infrastructure
Initialize and apply the Terraform configuration.

# Initialize providers and backend
terraform init

# Preview changes
terraform plan

# Apply changes (this takes 5-10 minutes, CloudFront is slow)
terraform apply --auto-approve

Step 4: Prepare the React Application
The pipeline will fail initially because your React repo doesn't know how to build itself on AWS.

Go to your React application's local project folder.

Create a file named buildspec.yml at the root of the project.

Add the following content. IMPORTANT: Check if your project builds to a build folder (Create React App) or a dist folder (Vite) and update the last line accordingly.

version: 0.2
phases:
  install:
    runtime-versions:
      nodejs: 20
    commands:
      - echo Installing dependencies...
      - npm install
  build:
    commands:
      - echo Building the React app...
      - npm run build
artifacts:
  files:
    - '**/*'
  base-directory: dist # <--- CHANGE to 'build' if not using Vite


  Push this file to GitHub:

git add buildspec.yml
git commit -m "Add buildspec for AWS Pipeline"
git push origin main

The push will automatically trigger the pipeline. Once complete, get your URL from the terraform outputs:



terraform output cloudfront_distribution_domain_name

File,Description
main.tf,Provider definitions and S3 backend configuration.
variables.tf,Input variable definitions.
terraform.tfvars,(Excluded from git) Your specific configuration values and secrets.
backend_setup.sh,Shell script to bootstrap the S3 state bucket and DynamoDB lock table.
s3.tf,Configuration for artifact and frontend hosting S3 buckets.
cloudfront.tf,CloudFront CDN distribution and OAC security policy.
codepipeline.tf,"The main pipeline resource defining Source, Build, and Deploy stages."
codebuild.tf,Definitions for the build project and cache invalidation project.
iam.tf,Roles and policies giving permissions to CodeBuild and CodePipeline.
outputs.tf,"Useful information displayed after deployment (e.g., CloudFront URL)."

🧹 Cleanup (Destroy)
To tear down all resources created by this project and stop incurring costs:

Note: The S3 buckets are configured with force_destroy = true, so they will be deleted even if they contain files.

Bash

terraform destroy --auto-approve

Would you like me to create a `.gitignore` file for this project next, to ensure you don't accidentally commit your sensitive `terraform.tfvars` file?