# Day 7: Terraform Type Constraints

This project demonstrates how to use strict **Type Constraints** in Terraform variables to ensure infrastructure configuration integrity.

## Project Overview

We define variables with specific types to validate inputs before Terraform attempts to create resources. This prevents configuration errors and ensures data consistency.

---

## 🔍 Code Walkthrough

### 1. Variables (`variables.tf`)
This file defines the inputs our module accepts. We use `type` to strictly enforce what kind of data is allowed.

- **Primitive Types**:
  - `string`: Simple text (e.g., `project_name`).
  - `number`: Integers or floats (e.g., `instance_count`).
  - `bool`: True or False (e.g., `enable_monitoring`).

- **Collection Types**:
  - `list(string)`: An ordered sequence. Usage: `allowed_ips = ["1.1.1.1", "2.2.2.2"]`.
  - `map(string)`: Key-value pairs. Usage: `tags = { Name = "Web", Env = "Dev" }`.
  - `set(string)`: **Unique** values only. If you provide duplicates (e.g., `["admin", "admin"]`), Terraform removes them automatically.

- **Structural Types**:
  - `object({...})`: Defines a complex structure. Our `database_config` acts like a "class" or "struct", requiring specific fields (`name`, `port`, `storage`) with specific types.
  - `tuple([...])`: A fixed-length sequence where each element can have a different type (though here we used all strings).

### 2. Main Logic (`main.tf`)
We use the `local_file` resource to simulate creating infrastructure. It generates a text file based on our variables.

**Key Concepts Used:**
- **Interpolation (`${...}`)**: Inserting variable values into strings.
  ```hcl
  Project: ${var.project_name}
  ```
- **Direct Access**: Accessing object properties.
  ```hcl
  Port: ${var.database_config.port}
  ```
- **Loops (`%{ for ... }`)**: Iterating over lists and maps to generate dynamic content.
  ```hcl
  %{ for ip in var.allowed_ips ~}
  - ${ip}
  %{ endfor ~}
  ```
  *(The `~` removes extra whitespace/newlines)*

### 3. Inputs (`terraform.tfvars`)
This is where we assign actual values to the variables.
- We deliberately assigned duplicate "Admin" roles to `user_roles`.
- **Result**: You will see in the output that the second "Admin" is ignored because the type is `set`.

### 4. Outputs (`outputs.tf`)
Returns information back to the CLI after `apply`.
- `unique_roles`: Shows the result of the `set` variable (duplicates removed).
- `db_connection`: formats a connection string from the `object` variable.

---

## 🚀 Usage

1.  **Initialize the project:**
    ```bash
    terraform init
    ```

2.  **Run with valid data:**
    ```bash
    terraform apply -auto-approve
    ```
    Check `config_dump.txt` to see the generated configuration.

3.  **Test Type Integrity (Expect Failure):**
    We included an `error.tfvars` file to demonstrate what happens when you use the wrong type.
    ```bash
    terraform plan -var-file="error.tfvars"
    ```
    **Result:** Terraform will error because `instance_count` is set to `"three"` (string) instead of a `number`.
