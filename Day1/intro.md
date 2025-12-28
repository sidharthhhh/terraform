# 🚀 30 Days of AWS Terraform

Welcome to my **#30DaysOfAWSTerraform** journey! I am starting this challenge to master how modern infrastructure is built using **Infrastructure as Code (IaC)**.

---

## 🌍 What is Terraform?
Terraform is an open-source Infrastructure as Code (IaC) tool created by HashiCorp. It allows you to:
* **Define** infrastructure using code (HashiCorp Configuration Language - HCL).
* **Provision, update, and manage** cloud resources safely and efficiently.

---

## 💡 Why Terraform is Used Today
Terraform has become the industry standard for several reasons:
* **Automates** cloud infrastructure provisioning.
* **Eliminates** manual configuration errors.
* **Consistency:** Ensures the same setup for Dev, Staging, and Production environments.
* **Collaboration:** configuration files can be version-controlled using Git.
* **Multi-Cloud:** Works across AWS, Azure, Google Cloud, and more.

---

## 🧰 IaC Tools in the Industry
While there are many tools available, Terraform is often preferred due to its **cloud-agnostic support**.

| Tool | Type / Ecosystem |
| :--- | :--- |
| **Terraform** | **Multi-cloud (Preferred)** |
| Pulumi | Code-based IaC (Python, TS, Go) |
| AWS CloudFormation / CDK / SAM | AWS Only |
| Azure ARM / Bicep | Azure Only |
| GCP Config Controller | GCP Only |

---

## ❓ Why Do We Need Terraform?

### ❌ Without IaC
* Manual setup processes (ClickOps).
* **Environment Drift:** Configurations change over time without tracking.
* "Works on my machine" issues.
* Hard to scale and reproduce infrastructure.

### ✅ With Terraform
* Infrastructure is treated as **Code**.
* **Repeatable & Consistent** deployments.
* **Version Control & Rollback** capabilities.

---

## 🏗️ Where Terraform is Used
Terraform is versatile and covers a wide range of infrastructure needs:
* ☁️ **Cloud Infrastructure:** VPC, EC2, IAM, etc.
* ☸️ **Kubernetes & Networking**
* 🗄️ **Databases & Storage**
* 🔄 **CI/CD Infrastructure**
* 🌐 **Multi-region Deployments**

---

## 🧑‍💻 Installation Guide

### 🐧 Linux (Ubuntu/Debian)
Run the following commands to install Terraform version 1.9.0:

```bash
sudo apt update
sudo apt install -y wget unzip

# Download Terraform
wget [https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip](https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip)

# Unzip and move to /usr/local/bin
unzip terraform_1.9.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version