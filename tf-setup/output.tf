output "region" {
  value       = aws_s3_bucket.terraform_state[*].region
  description = "The name of the region"
}

output "s3_bucket" {
  value       = aws_s3_bucket.terraform_state[*].bucket
  description = "The ARN of the S3 bucket"
}