resource "aws_ssm_parameter" "tf-eks-id" {
  name        = "/workshop/tf-eks/id"
  description = "The unique id for the workshop"
  type        = "String"
  value       = random_id.id1.hex

  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "tf-eks-keyid" {
  name        = "/workshop/tf-eks/keyid"
  description = "The keyid for the workshop"
  type        = "String"
  value       = aws_kms_key.ekskey.key_id

  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "tf-eks-region" {
  name        = "/workshop/tf-eks/region"
  description = "The region for the workshop"
  type        = "String"
  value       = var.region

  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "tf-eks-cluster-name" {
  name        = "/workshop/tf-eks/cluster-name"
  description = "The EKS cluster name for the workshop"
  type        = "String"
  value       = var.cluster-name

  tags = {
    workshop = "tf-eks-workshop"
  }
}

