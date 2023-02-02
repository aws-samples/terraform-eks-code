resource "aws_ecr_repository" "sample-app" {
  name                 = "sample-app"
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

resource "aws_ecr_repository" "karpenter-webhook" {
  name                 = "karpenter/webhook"
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

resource "aws_ecr_repository" "karpenter-controller" {
  name                 = "karpenter/controller"
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


resource "aws_ecr_repository" "pause" {
  name                 = "pause"
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