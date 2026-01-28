# Terraform Conftest Demo

Demo of Terraform plan validation using Conftest and Open Policy Agent (OPA). This example shows how to enforce policies on Terraform configurations before they're applied.

## Overview

This project demonstrates how to:

- Write OPA policies in Rego to validate Terraform plans
- Test policies locally using Conftest
- Integrate policy validation into GitHub Actions CI/CD pipeline
- Catch infrastructure violations before they reach production

## Project Structure

```text
.
├── policies/
│   └── main.rego          # OPA policy definitions
├── fail.tf                 # Example that violates the policy
├── pass.tf                 # Example that passes the policy
└── README.md
```

## The Policy

The example policy (`policies/main.rego`) denies the creation of `null_resource` resources:

```rego
deny contains msg if {
  num_resources := num_creates["null_resource"]
  num_resources > 0
  msg := "null resources cannot be created"
}
```

## Example Terraform Files

### Failing Example (`fail.tf`)

This file creates a `null_resource`, which violates the policy:

```hcl
resource "null_resource" "test" {
  triggers = {
    test = "value"
  }
}
```

**Result:** ❌ Policy violation - "null resources cannot be created"

### Passing Example (`pass.tf`)

This file creates a `random_id` resource, which is allowed:

```hcl
resource "random_id" "test" {
  byte_length = 4
}
```

**Result:** ✅ Policy passes

## Testing Locally

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html)
- [Conftest](https://www.conftest.dev/install/)

### Steps

1. Initialize Terraform:

```bash
terraform init
```

1. Generate a Terraform plan:

```bash
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > plan.json
```

1. Run Conftest against the plan:

```bash
conftest test plan.json --policy policies/
```

### Expected Output

For `fail.tf`:

```text
FAIL - plan.json - main - null resources cannot be created
```

For `pass.tf`:

```text
PASS - plan.json
```

## GitHub Actions Integration

This repository includes a GitHub Actions workflow that automatically runs Conftest on pull requests.

### Workflow Features

- ✅ Runs on all pull requests
- ✅ Validates Terraform configurations
- ✅ Generates plan and runs Conftest
- ✅ Reports violations in PR comments
- ✅ Blocks merging if policies fail

### Workflow Configuration

The workflow uses the [actionsforge/actions-terraform-conftest](https://github.com/actionsforge/actions-terraform-conftest) action:

```yaml
- name: Run Terraform Conftest
  id: conftest
  uses: actionsforge/actions-terraform-conftest@v1
  with:
    conftest-version: 'v0.66.0'
    terraform-version: '1.6.0'
    policy-path: './policies'
    working-directory: './'
    run-terraform-plan: 'true'
    run-conftest: 'true'
```

## Use Cases

This pattern is useful for:

- **Security compliance**: Enforce security policies (e.g., no public S3 buckets)
- **Cost control**: Limit expensive resource types
- **Standards enforcement**: Require specific tags or naming conventions
- **Best practices**: Ensure encryption, backups, or monitoring are configured

## Extending the Policies

To add more policies, edit `policies/main.rego`:

```rego
# Example: Deny public S3 buckets
deny contains msg if {
  some resource in input.resource_changes
  resource.type == "aws_s3_bucket"
  resource.change.after.acl == "public-read"
  msg := "S3 buckets cannot be public"
}

# Example: Require tags
deny contains msg if {
  some resource in input.resource_changes
  not resource.change.after.tags.Environment
  msg := sprintf("Resource %s must have an Environment tag", [resource.address])
}
```

## Resources

- [Conftest Documentation](https://www.conftest.dev/)
- [Open Policy Agent (OPA)](https://www.openpolicyagent.org/)
- [Rego Language Guide](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [Terraform JSON Output Format](https://www.terraform.io/docs/internals/json-format.html)

## License

See [LICENSE](LICENSE) file for details.
