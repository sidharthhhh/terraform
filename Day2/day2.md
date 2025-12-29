# Day 2 — Terraform Basics, Workflow & Versioning

This repository contains my **Day 2 notes** from the **#30DaysOfAWSTerraform** learning series.
The focus is on understanding Terraform fundamentals, workflow, registry, providers, plugins,
versioning, and basic AWS configuration.

---

## What is Terraform?

Terraform is an **Infrastructure as Code (IaC)** tool by HashiCorp that allows you to define,
provision, and manage infrastructure using **HCL (HashiCorp Configuration Language)**.

Terraform is **declarative**, meaning you describe the desired state of infrastructure,
and Terraform figures out how to achieve it.

---

## Topics Covered

- Terraform basics
- HCL (HashiCorp Configuration Language)
- Terraform workflow
- Terraform Registry
- Provider types (Official, Partner, Community)
- Cloud providers (AWS, Azure, GCP)
- Service providers (Docker, Kubernetes, Datadog)
- Providers, plugins, and target APIs
- Terraform versions and compatibility
- Version constraints and rules
- Core Terraform commands
- Basic Terraform configuration with AWS
- Importance of Terraform documentation

---

## Terraform Workflow

Terraform follows a simple and predictable workflow:

```text
Write Configuration (HCL)
        ↓
terraform init
        ↓
terraform plan
        ↓
terraform apply

Core Commands
| Command           | Description                                     |
| ----------------- | ----------------------------------------------- |
| terraform init    | Initializes the project and downloads providers |
| terraform plan    | Shows planned infrastructure changes            |
| terraform apply   | Applies changes to infrastructure               |
| terraform destroy | Destroys managed infrastructure                 |


Terraform Registry & Providers

Terraform uses providers to interact with cloud platforms and services.
Providers act as plugins that communicate with target APIs.

Provider Types

Official (maintained by HashiCorp)

Partner (maintained by verified companies)

Community (open-source maintained)

Common Providers

Cloud: AWS, Azure, GCP

Services: Docker, Kubernetes, Datadog


Providers, Plugins & Target APIs

Provider: Interface for a cloud or service

Plugin: Binary downloaded during terraform init

Target API: Actual cloud/service API Terraform communicates with

Terraform core never talks directly to infrastructure—providers do.

Terraform Versions & Why They Matter

By default, Terraform may use the latest version, which can introduce:

Breaking changes

Deprecated arguments

Incompatible configurations

To avoid this, Terraform supports version constraints.

Version Constraints Example
terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


Explanation

~> 1.6 → Allows Terraform 1.6.x, blocks 1.7+

~> 5.0 → Allows AWS provider 5.x, blocks 6.0+

Basic AWS Provider Configuration
provider "aws" {
  region = "ap-south-1"
}


Running Terraform
terraform init
terraform plan
terraform apply


Best Practices Learned

Always pin Terraform and provider versions

Never skip terraform plan

Use official providers when possible

Read Terraform documentation before using new resources

Keep configurations simple and readable

Key Takeaways

Terraform uses declarative IaC

Providers bridge Terraform and APIs

Registry simplifies provider discovery

Version constraints ensure stability

Workflow prevents accidental changes