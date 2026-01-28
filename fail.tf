# Test Terraform configuration to verify OPA policies
# This creates a null_resource which should be denied by the policy

resource "null_resource" "test" {
  triggers = {
    test = "value"
  }
}

