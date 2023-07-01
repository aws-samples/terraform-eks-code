
resource "aws_s3_bucket" "terraform_state" {

  bucket = format("tf-state-workshop-%s", random_id.id1.hex)

  // This is only here so we can destroy the bucket as part of automated tests. You should not copy this for production
  // usage
  force_destroy = true



  lifecycle {
    ignore_changes = [bucket]
  }

}

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


resource "aws_s3_bucket_versioning" "terraform_state" {
  # Enable versioning so we can see the full revision history of our
  # state files
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_public_access_block" "pub_block_state" {
  bucket = aws_s3_bucket.terraform_state.id

  restrict_public_buckets = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
}

