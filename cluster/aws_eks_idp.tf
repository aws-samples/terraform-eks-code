resource "aws_eks_identity_provider_config" "oidc" {
  cluster_name = aws_eks_cluster.cluster.name

  oidc {
    client_id                     = "sts.amazonaws.com"
    identity_provider_config_name = aws_eks_cluster.cluster.name
    issuer_url                    = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
  }
}