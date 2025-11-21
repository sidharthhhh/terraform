# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "A unique prefix for all resources"
  type        = string
  default     = "react-cicd-project"
}

variable "github_repo_owner" {
  description = "sidharthhhh"
  type        = string
}

variable "github_repo_name" {
  description = "portfoliooooo"
  type        = string
}

variable "github_branch" {
  description = "The branch to monitor for code changes"
  type        = string
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "ARN of the CodeStar Connection to GitHub"
  type        = string
}