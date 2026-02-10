# Outputs from tf-setup Stage
# These values are used by the gen-backend.sh script

# Region where the S3 bucket was created
output "region" {
  value       = aws_s3_bucket.terraform_state[*].region
  description = "The name of the region"
  # Note: Using splat operator [*] but only one bucket exists
  # Could be simplified to: aws_s3_bucket.terraform_state.region
}

# S3 bucket name for Terraform state storage
output "s3_bucket" {
  value       = aws_s3_bucket.terraform_state[*].bucket
  description = "The ARN of the S3 bucket"
  # Note: Description says ARN but returns bucket name
  # Note: Using splat operator [*] but only one bucket exists
}