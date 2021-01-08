resource "aws_s3_bucket" "codepipeline-eu-west-1-439945733742" {
  bucket = "codepipeline-eu-west-1-421985771879"
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
