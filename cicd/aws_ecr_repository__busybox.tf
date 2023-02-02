resource "aws_ecr_repository" "busybox" {
  name                 = "busybox"
  image_tag_mutability = "IMMUTABLE"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
    encryption_configuration {
        encryption_type = "KMS"
        kms_key = data.aws_ssm_parameter.tf-eks-keyid.value
  }
}