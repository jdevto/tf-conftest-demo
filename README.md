# tf-conftest-demo
Demo of Terraform plan validation using Conftest and Open Policy Agent

# OPA Policy Testing

This directory contains test Terraform configurations to verify the OPA policies work correctly before deploying them to Atlantis.

## Overview

This test setup allows you to:
- Test OPA/Rego policies locally before using them in Atlantis
- Verify that policies correctly detect violations
- Debug policy logic without waiting for Atlantis runs

## Prerequisites

### 1. Terraform

Install Terraform (any recent version). Verify installation:
```bash
terraform --version
```

### 2. Conftest

Conftest is the tool that runs OPA policies against Terraform plan JSON. Install it as follows:

#### Linux Installation (Recommended)

```bash
# Download the latest release
wget https://github.com/open-policy-agent/conftest/releases/download/v0.66.0/conftest_0.66.0_Linux_x86_64.tar.gz

# Extract the binary
tar xzf conftest_0.66.0_Linux_x86_64.tar.gz

# Install to ~/bin (no sudo required)
mkdir -p ~/bin
mv conftest ~/bin/
chmod +x ~/bin/conftest

# Verify installation
conftest --version
```

**Important:** Make sure `~/bin` is in your PATH. Check with:
```bash
echo $PATH | grep -q "$HOME/bin" && echo "✓ ~/bin is in PATH" || echo "✗ ~/bin is NOT in PATH"
```

If `~/bin` is not in your PATH, add this to your `~/.bashrc` or `~/.zshrc`:
```bash
export PATH="$HOME/bin:$PATH"
```

Then reload your shell:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

#### Alternative Installation Methods

- **macOS (Homebrew):** `brew install conftest`
- **Go (if you have Go 1.25.3+):** `go install github.com/open-policy-agent/conftest@latest`

## Running the Test

### Quick Start (Automated)

The easiest way to run the test is using the provided script:

```bash
cd test
./test.sh
```

This script will:
1. Initialize Terraform
2. Generate a plan
3. Convert it to JSON
4. Run conftest against the plan
5. Clean up temporary files

### Manual Steps

If you prefer to run the steps manually:

#### Step 1: Generate Terraform Plan

```bash
cd test
terraform init
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > plan.json
```

#### Step 2: Run Conftest Against the Plan

```bash
# From the test directory
conftest test plan.json -p ../policies/deny_null_resource
```

### Expected Result

The policy should **FAIL** (exit code 1) because `main.tf` creates a `null_resource`, which is denied by the policy.

You should see output like:
```
FAIL - plan.json - main - null resources cannot be created

1 test, 0 passed, 0 warnings, 1 failure, 0 exceptions
```

**Note:** A failure here is expected and correct! The policy is working as intended by blocking `null_resource` creation.

## Understanding the Test

### Current Test Configuration

The `test/main.tf` file creates a `null_resource`, which is explicitly denied by the policy in `policies/deny_null_resource/main.rego`. This is an intentional violation to verify the policy works correctly.

### Policy Location

The policy being tested is located at:
```
policies/deny_null_resource/main.rego
```

This policy:
- Checks all resources in the Terraform plan
- Counts how many `null_resource` resources are being created
- Denies the plan if any `null_resource` creations are detected

### Test Script Details

The `test.sh` script:
- Automatically runs all test steps
- Cleans up temporary files after completion
- Returns exit code 1 if policy violations are found (expected for this test)
- Returns exit code 0 if no violations are found

## Troubleshooting

### Conftest Not Found

If you see `conftest: command not found`:
1. Verify conftest is installed: `which conftest`
2. Check if `~/bin` is in your PATH: `echo $PATH`
3. If not, add it to your shell config and reload

### Policy Syntax Errors

If you see Rego syntax errors, ensure you're using the correct syntax for your conftest version:
- Conftest 0.66.0+ requires `import future.keywords.if`, `import future.keywords.in`, and `import future.keywords.contains`
- Rules must use `if` keyword: `deny contains msg if { ... }`

### Terraform Errors

If Terraform fails:
- Ensure you have valid AWS credentials (if testing with AWS resources)
- Check that `main-passing.tf.disabled` is not being loaded (it requires AWS)
- The current `main.tf` only uses `null_resource` which doesn't require credentials

## File Structure

```
test/
├── README.md          # This file
├── test.sh            # Automated test script
├── main.tf            # Test Terraform config (creates null_resource - should fail)
└── .terraform/        # Terraform state (gitignored)

policies/
└── deny_null_resource/
    └── main.rego      # OPA policy that denies null_resource creation
```

## Integration with Atlantis

Once you've verified the policy works locally:

1. The policy is already configured in the repository at `policies/deny_null_resource/main.rego`
2. Atlantis server configuration should reference this policy path
3. The policy will run automatically during Atlantis plan operations
4. Plans that violate the policy will be blocked from applying

## Cleanup

The test script automatically cleans up temporary files. To manually clean up:

```bash
cd test
rm -f plan.json tfplan.binary
rm -rf .terraform
```

## Additional Resources

- [Conftest Documentation](https://www.conftest.dev/)
- [OPA/Rego Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Atlantis Policy Checking](https://www.runatlantis.io/docs/policy-checking.html)

