data "aws_eks_cluster" "mycluster" {
  name = data.terraform_remote_state.cluster.outputs.cluster-name
}

output "endpoint" {
  value = data.aws_eks_cluster.mycluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = data.aws_eks_cluster.mycluster.certificate_authority[0].data
}

# Only available on Kubernetes version 1.13 and 1.14 clusters created or upgraded on or after September 3, 2019.
output "identity-oidc-issuer" {
  value = data.aws_eks_cluster.mycluster.identity[0].oidc[0].issuer
}