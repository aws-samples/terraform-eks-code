
data "external" "bucket_name" {
  program = ["bash", "get-bucket-name.sh"]
}

output "Name" {
  value = data.external.bucket_name.result.Name
}

resource "aws_s3_bucket" "codepipeline-bucket" {
  bucket = data.external.bucket_name.result.Name
  hosted_zone_id = "Z1BKCTXD74EZPE"
  request_payer  = "BucketOwner"
  tags           = {}

  versioning {
    enabled    = false
    mfa_delete = false
  }
  force_destroy = false
  acl           = "private"
}
