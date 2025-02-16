data "aws_iam_openid_connect_provider" "example" {
  depends_on = [module.eks]
  #url = "https://oidc.eks.eu-west-2.amazonaws.com/id/92689730BC26F44B10C02F4412A09911"
  url=  format("https://%s",module.eks.oidc_provider)
}

data "aws_eks_cluster" "example" {
  depends_on = [module.eks]
  name = module.eks.cluster_name
}

#output "endpoint" {
#  value = data.aws_eks_cluster.example.endpoint
#}

# Only available on Kubernetes version 1.13 and 1.14 clusters created or upgraded on or after September 3, 2019.
#output "identity-oidc-issuer" {
#  value = data.aws_eks_cluster.example.identity[0].oidc[0].issuer
#}


