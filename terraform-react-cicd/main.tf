# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "sidharth-terraform-cicd" # MUST be globally unique
    key            = "react-cicd/terraform.tfstate"
    region         = "us-east-1" # State bucket often resides in a single region
    encrypt        = true
    dynamodb_table = "sidharth-terraform-cicd-table"
  }
}

provider "aws" {
  region = var.aws_region
}