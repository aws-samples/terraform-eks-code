
#data "external" "bucket_name" {
#  program = ["bash", "get-bucket-name.sh"]
#}

#output "Name" {
#  value = data.external.bucket_name.result.Name
#}

resource "aws_s3_bucket" "codepipeline-bucket" {
  #bucket = data.external.bucket_name.result.Name
  bucket = format("codep-tfeks-%s", data.aws_ssm_parameter.tf-eks-id.value)
  tags   = {}

  force_destroy = false

}

resource "aws_s3_bucket_versioning" "codepipeline-bucket" {
  # Enable versioning so we can see the full revision history of our
  # state files
  bucket = aws_s3_bucket.codepipeline-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_request_payment_configuration" "codepipeline-bucket" {
  bucket = aws_s3_bucket.codepipeline-bucket.id
  payer  = "BucketOwner"
}

resource "aws_s3_bucket_acl" "codepipeline-bucket" {
  bucket = aws_s3_bucket.codepipeline-bucket.id
  acl    = "private"
}



resource "aws_s3_bucket_public_access_block" "pub_block_state" {
  bucket = aws_s3_bucket.codepipeline-bucket.id

  restrict_public_buckets = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.codepipeline-bucket.id

  rule {
    bucket_key_enabled = false

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_ssm_parameter.tf-eks-keyid.value
    }
  }
}

