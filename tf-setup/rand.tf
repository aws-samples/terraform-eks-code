# Random ID Generator
# Creates a unique identifier used throughout the infrastructure
# This ensures resource names don't conflict with existing resources

resource "random_id" "id1" {
  byte_length = 8  # Generates 16-character hex string
}

# Output the random ID for use in resource naming and SSM parameters
output "tfid" {
  value = random_id.id1.hex
}

