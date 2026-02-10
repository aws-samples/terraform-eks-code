# KMS Key for Terraform State Encryption
# This key encrypts the S3 bucket containing all Terraform state files

resource "aws_kms_key" "ekskey" {
  description = format("EKS KMS Key 2 %s", var.cluster-name)
  # Note: Key rotation not enabled - consider enabling for production
  # Note: Using default key policy - consider custom policy for production
}

# Output the key ID for use in S3 encryption and SSM parameters
output "keyid" {
  value = aws_kms_key.ekskey.key_id
}