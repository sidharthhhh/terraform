# Day 7: Terraform Type Constraints

This project demonstrates how to use strict **Type Constraints** in Terraform variables to ensure infrastructure configuration integrity.

## Project Overview

We define variables with specific types to validate inputs before Terraform attempts to create resources. This prevents configuration errors and ensures data consistency.

### Variable Types Covered

| Type | Description | Example Variable |
| :--- | :--- | :--- |
| `string` | Single line of text | `project_name` |
| `number` | Numeric value | `instance_count` |
| `bool` | True/False value | `enable_monitoring` |
| `list(string)` | Ordered sequence of strings | `allowed_ips` |
| `map(string)` | Key-value pairs | `resource_tags` |
| `set(string)` | Unordered collection of unique values | `user_roles` |
| `object({...})` | Structured data with specific properties | `database_config` |
| `tuple([...])` | Fixed-length sequence with typed elements | `subnet_cidrs` |

## Files

- **`variables.tf`**: Defines strict types for all variables.
- **`terraform.tfvars`**: Provides valid input values.
- **`error.tfvars`**: Contains invalid values to demonstrate type safety.
- **`main.tf`**: Mocks infrastructure resources using `local_file` to output the variable values.
- **`outputs.tf`**: Displays processed values (e.g., showing how `set` removed duplicates).

## Usage

1.  **Initialize the project:**
    ```bash
    terraform init
    ```

2.  **Run with valid data:**
    ```bash
    terraform apply -auto-approve
    ```
    Check the generated `config_dump.txt` file to see how inputs were processed.

3.  **Test Type Integrity (Expect Failure):**
    Try to run with invalid data types:
    ```bash
    terraform plan -var-file="error.tfvars"
    ```
    Terraform will reject the plan because `instance_count` is passed as a string ("three") instead of a number.
