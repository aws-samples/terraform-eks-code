# S3 Bucket for Terraform State Storage
# This bucket stores state files for all stages of the infrastructure

# Main state bucket with unique name
resource "aws_s3_bucket" "terraform_state" {

  bucket = format("tf-state-workshop-%s", random_id.id1.hex)

  # WARNING: force_destroy is enabled for workshop/demo purposes only
  # This allows easy cleanup but should NEVER be used in production
  # In production, state buckets should be protected from deletion
  force_destroy = true
  
  # Prevent bucket name changes after creation
  # This avoids accidental state migration issues
  lifecycle {
    ignore_changes = [bucket]
  }

}

# Enable KMS encryption for all objects in the bucket
# Ensures state files are encrypted at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    bucket_key_enabled = false

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.ekskey.key_id
    }
  }
}

# Enable versioning for state file history
# Allows recovery from accidental state corruption or deletion
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access to the state bucket
# State files contain sensitive information and should never be public
resource "aws_s3_bucket_public_access_block" "pub_block_state" {
  bucket = aws_s3_bucket.terraform_state.id

  restrict_public_buckets = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
}

