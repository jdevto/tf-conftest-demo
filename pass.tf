# Example of a passing test case
# This uses random_id instead of null_resource, so it should pass the policy check
# Note: Rename this file to main.tf to test a passing case
# This file is disabled by default (renamed to .tf.disabled) to avoid conflicts

resource "random_id" "test" {
  byte_length = 4
}

