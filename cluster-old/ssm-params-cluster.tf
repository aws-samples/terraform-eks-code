resource "aws_ssm_parameter" "oidc_provider_arn" {
  name        = "/workshop/tf-eks/oidc_provider_arn"
  description = "The EKS cluster oidc arn"
  type        = "String"
  #value = aws_iam_openid_connect_provider.cluster.arn
  value = module.eks.oidc_provider_arn
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "cluster-name" {
  name        = "/workshop/tf-eks/eks-cluster-name"
  description = "The actual EKS cluster name"
  type        = "String"
  value = module.eks.cluster_name
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "cluster-sg" {
  name        = "/workshop/tf-eks/cluster-sg"
  description = "The EKS cluster created sg"
  type        = "String"
  value = module.eks.cluster_primary_security_group_id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "ca" {
  name        = "/workshop/tf-eks/ca"
  description = "The EKS cluster cert authority"
  type        = "String"
  value = module.eks.cluster_certificate_authority_data
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "endpoint" {
  name        = "/workshop/tf-eks/endpoint"
  description = "The EKS cluster endpoint"
  type        = "String"
  value = module.eks.cluster_endpoint
  tags = {
    workshop = "tf-eks-workshop"
  }
}
