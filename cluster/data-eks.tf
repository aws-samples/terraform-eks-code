# EKS Cluster and OIDC Provider Data Sources
# Retrieves information about the created cluster and OIDC provider
# Used for validation and additional configuration

# OIDC Provider Data Source
# Retrieves the IAM OIDC provider created for IRSA
data "aws_iam_openid_connect_provider" "example" {
  depends_on = [module.eks]
  
  # Construct OIDC provider URL from cluster output
  url = format("https://%s", module.eks.oidc_provider)
}

# EKS Cluster Data Source
# Retrieves detailed cluster information
data "aws_eks_cluster" "example" {
  depends_on = [module.eks]
  name = module.eks.cluster_name
}

# Cluster endpoint output (commented out - available in outputs.tf)
#output "endpoint" {
#  value = data.aws_eks_cluster.example.endpoint
#}

# OIDC issuer output (commented out - available in outputs.tf)
# Only available on Kubernetes version 1.13 and 1.14 clusters created or upgraded on or after September 3, 2019.
#output "identity-oidc-issuer" {
#  value = data.aws_eks_cluster.example.identity[0].oidc[0].issuer
#}


