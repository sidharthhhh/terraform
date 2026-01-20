# Terraform Infrastructure as Code (IaC) Journey

Welcome to this repository documenting a comprehensive journey into Infrastructure as Code using **Terraform**. This collection contains progressive learning modules and real-world projects designed to master cloud infrastructure provisioning on AWS.

## 📂 Repository Structure

### 📚 Learning Modules
Foundation concepts and step-by-step Terraform implementations.

| Module | Description | Key Concepts |
|:---|:---|:---|
| **[Day 1](./Day1)** | **Introduction & Theory** | IaC Principles, Terraform vs. Ansible, HCL Syntax |
| **[Day 2](./Day2)** | **Terraform Workflow** | Lifecycle commands (`init`, `plan`, `apply`, `destroy`), State Management |
| **[Day 3](./day3)** | **Basic Resources** | Defining Resources, Simple S3 Bucket Provisioning |
| **[Day 4](./day4)** | **Providers & Backend** | Configuring AWS Provider, State Backend Configuration |
| **[Day 5](./day5)** | **Variables & Logic** | Input Variables, Locals, Output Values, Random Providers |
| **[Day 6](./day6)** | **File Organization & VPC** | Modern File Structure, VPC Networking, Security Groups, EC2 in VPC |
| **[Day 7](./day7)** | **Type Constraints** | Primitive Types, Collection Types, Structural Types, Type Validation |

### 🚀 Projects
Applied infrastructure scenarios and complex deployments.

| Project | Title | Description |
|:---|:---|:---|
| **[Project 1](./Project1)** | **Intermediate Infrastructure** | Expanded resource management and dependency handling. |
| **[Project 2](./Project2)** | **Nginx Web Server** | Provisioning EC2 instances and bootstrapping Nginx via user-data. |
| **[Project 3](./Project3)** | **Static Website Hosting** | Hosting a static website on S3 with public access policies. |
| **[EC2](./ec2)** | **EC2 Instance Configuration** | Complete EC2 setup with security groups, Elastic IP, encrypted volumes, and snapshot management. |
| **[CICD](./terraform-react-cicd)** | **Terraform + React CI/CD** | Full-stack deployment pipeline for a React application. |

## 🛠️ Tech Stack
-   **Core**: Terraform (HCL)
-   **Cloud Provider**: AWS (Amazon Web Services)
-   **tools**: Git, VS Code

## ⚡ Quick Start

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    ```
2.  **Navigate to a module (e.g., Day 5):**
    ```bash
    cd day5
    ```
3.  **Initialize & Apply:**
    ```bash
    terraform init
    terraform apply
    ```

---
*Created by Sidharth*
