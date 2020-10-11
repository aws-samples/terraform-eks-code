output "s3_bucket" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table"
}


output "region" {
  value       = aws_s3_bucket.terraform_state.region
  description = "The name of the DynamoDB table"
}