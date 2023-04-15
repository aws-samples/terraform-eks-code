resource "aws_ssm_parameter" "oidc_provider_arn" {
  name        = "/workshop/tf-eks/oidc_provider_arn"
  description = "The EKS cluster oidc arn"
  type        = "String"
  #value = aws_iam_openid_connect_provider.cluster.arn
  value = aws_eks_identity_provider_config.oidc.arn
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "cluster-name" {
  name        = "/workshop/tf-eks/eks-cluster-name"
  description = "The actual EKS cluster name"
  type        = "String"
  value = aws_eks_cluster.cluster.name
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "cluster-sg" {
  name        = "/workshop/tf-eks/cluster-sg"
  description = "The EKS cluster created sg"
  type        = "String"
  value = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "ca" {
  name        = "/workshop/tf-eks/ca"
  description = "The EKS cluster cert authority"
  type        = "String"
  value = aws_eks_cluster.cluster.certificate_authority[0].data
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "endpoint" {
  name        = "/workshop/tf-eks/endpoint"
  description = "The EKS cluster endpoint"
  type        = "String"
  value = aws_eks_cluster.cluster.endpoint
  tags = {
    workshop = "tf-eks-workshop"
  }
}
