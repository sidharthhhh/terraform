# Day 8: Terraform Meta-Arguments

## 📚 Overview
Meta-arguments are special arguments that can be used with any resource block to change the behavior of resources. They are built into Terraform and provide powerful ways to control resource creation, dependencies, and lifecycle.

## 🎯 Topics Covered
1. **count** - Create multiple resources with numeric indexing
2. **for_each** - Create multiple resources with maps/sets
3. **depends_on** - Explicit resource dependencies
4. **lifecycle** - Control resource creation and destruction behavior
5. **provider** - Use alternate provider configurations
6. **Output transformations** with for expressions
7. **Best practices** for each meta-argument

---

## 1️⃣ Count Meta-Argument

### What is Count?
The `count` meta-argument accepts a whole number and creates that many instances of the resource. Each instance has a distinct infrastructure object associated with it.

### Key Points:
- Creates numbered instances (0, 1, 2, ...)
- Access instances using `count.index`
- Total count available as `count.count` (rarely used)
- Best for creating identical resources
- Resources are identified by their index number

### When to Use:
✅ Creating multiple identical resources
✅ Simple numeric repetition
✅ When you don't need named keys
❌ When you need to identify resources by name/key
❌ When removing items from the middle of a list

### Example 1: Basic Count
See `01-count-basic/`

### Example 2: Count with Conditional
See `02-count-conditional/`

### Example 3: Count with List
See `03-count-with-list/`

---

## 2️⃣ For_Each Meta-Argument

### What is For_Each?
The `for_each` meta-argument accepts a map or set of strings and creates one instance for each item in that map or set.

### Key Points:
- Creates instances with unique keys
- Access current item using `each.key` and `each.value`
- Better than count for managing multiple similar resources
- Resources identified by their key (not index)
- Safer when adding/removing items

### When to Use:
✅ Creating resources with unique identifiers
✅ When you might add/remove items
✅ When each instance has different configurations
✅ Managing multiple similar but not identical resources
❌ Simple numeric repetition (use count)

### Example 1: For_Each with Set
See `04-foreach-set/`

### Example 2: For_Each with Map
See `05-foreach-map/`

### Example 3: For_Each with Complex Map
See `06-foreach-complex/`

---

## 3️⃣ Depends_On Meta-Argument

### What is Depends_On?
Explicitly specifies dependencies between resources when Terraform can't automatically detect them.

### Key Points:
- Use only when necessary (Terraform handles most dependencies automatically)
- Accepts a list of resource or module references
- Creates explicit ordering
- Useful for hidden dependencies (e.g., IAM permissions)

### When to Use:
✅ Hidden dependencies not in resource arguments
✅ Ensuring IAM policies are ready before use
✅ Dependencies on module outputs
✅ Complex ordering requirements
❌ Dependencies already expressed in resource arguments (Terraform auto-detects these)

### Example 1: Basic Depends_On
See `07-depends-on-basic/`

### Example 2: Depends_On with Multiple Resources
See `08-depends-on-multiple/`

---

## 4️⃣ Lifecycle Meta-Argument

### What is Lifecycle?
Controls specific behaviors during resource creation, updating, and deletion.

### Lifecycle Options:

#### create_before_destroy (bool)
- Creates replacement before destroying the original
- Useful for zero-downtime updates

#### prevent_destroy (bool)
- Prevents accidental resource deletion
- Terraform will error if you try to destroy
- Good for protection of critical resources

#### ignore_changes (list)
- Ignores changes to specified attributes
- Prevents Terraform from reverting manual changes
- Useful when external systems modify resources

#### replace_triggered_by (list)
- Forces replacement when specified resources change
- Available in Terraform 1.2+

### When to Use:
✅ `create_before_destroy`: For resources that can't have downtime
✅ `prevent_destroy`: For critical databases, storage, etc.
✅ `ignore_changes`: When external tools modify resources
✅ `replace_triggered_by`: When resources depend on others changing

### Example 1: Create Before Destroy
See `09-lifecycle-create-before-destroy/`

### Example 2: Prevent Destroy
See `10-lifecycle-prevent-destroy/`

### Example 3: Ignore Changes
See `11-lifecycle-ignore-changes/`

---

## 5️⃣ Provider Meta-Argument

### What is Provider?
Specifies which provider configuration to use for a resource. Useful for multi-region or multi-account deployments.

### Key Points:
- Overrides default provider selection
- Enables multi-region deployments
- Allows multi-account AWS configurations
- Use aliases to differentiate providers

### When to Use:
✅ Multi-region deployments
✅ Multi-account AWS setups
✅ DR/backup resources in different regions
✅ Cross-region resource dependencies

### Example 1: Multi-Region Deployment
See `12-provider-multi-region/`

---

## 6️⃣ For Expressions in Outputs

### What are For Expressions?
Transform and filter collections of values. Similar to list comprehensions in Python.

### Syntax:
```hcl
# For list → list
[for item in list : transform(item)]

# For list → map
{for item in list : item.key => item.value}

# For map → list
[for key, value in map : "${key}=${value}"]

# For map → map
{for key, value in map : key => upper(value)}

# With filtering
[for item in list : item.name if item.enabled]
```

### When to Use:
✅ Transforming output formats
✅ Filtering collections
✅ Creating maps from lists
✅ Extracting specific attributes

### Example: Advanced For Expressions
See `13-for-expressions/`

---

## 🎯 Best Practices Summary

### Count vs For_Each
| Scenario | Use |
|:---|:---|
| Fixed number of identical resources | `count` |
| Resources with unique identifiers | `for_each` |
| Might add/remove items | `for_each` |
| Simple 0-N iteration | `count` |

### Depends_On
- ⚠️ Use sparingly - Terraform auto-detects most dependencies
- ✅ Document why it's needed
- ✅ Use for hidden dependencies only

### Lifecycle
- ✅ `create_before_destroy` for minimal downtime
- ✅ `prevent_destroy` for critical resources (databases, etc.)
- ⚠️ `ignore_changes` can cause drift - use carefully
- 📝 Always document lifecycle customizations

### Provider
- ✅ Use clear alias names (e.g., `aws.us-east-1`)
- ✅ Define all providers in root module
- ✅ Document multi-region intentions

### For Expressions
- ✅ Keep expressions simple and readable
- ✅ Use for complex transformations
- ✅ Comment complex logic
- ⚠️ Avoid deeply nested expressions

---

## 📂 Project Structure
```
day8/
├── README.md (this file)
├── 01-count-basic/
├── 02-count-conditional/
├── 03-count-with-list/
├── 04-foreach-set/
├── 05-foreach-map/
├── 06-foreach-complex/
├── 07-depends-on-basic/
├── 08-depends-on-multiple/
├── 09-lifecycle-create-before-destroy/
├── 10-lifecycle-prevent-destroy/
├── 11-lifecycle-ignore-changes/
├── 12-provider-multi-region/
└── 13-for-expressions/
```

---

## 🚀 How to Use

Each subdirectory contains a complete, working example:

1. Navigate to the example:
   ```bash
   cd 01-count-basic
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the plan:
   ```bash
   terraform plan
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

5. Check outputs:
   ```bash
   terraform output
   ```

6. Clean up:
   ```bash
   terraform destroy
   ```

---

## 📖 Learning Path
1. Start with `01-count-basic` to understand basic replication
2. Progress through `count` examples (01-03)
3. Move to `for_each` examples (04-06) and compare with count
4. Learn `depends_on` for dependency management (07-08)
5. Master `lifecycle` for resource behavior control (09-11)
6. Explore `provider` for multi-region (12)
7. Practice `for` expressions for data transformation (13)

---

## 🎓 Key Takeaways
- Meta-arguments modify resource behavior beyond configuration
- Choose `for_each` over `count` for most use cases
- Use `depends_on` only when necessary
- Lifecycle blocks protect critical resources
- Provider aliases enable multi-region architectures
- For expressions transform data efficiently

---

*Day 8 of Terraform Learning Journey - Meta-Arguments Mastery*
