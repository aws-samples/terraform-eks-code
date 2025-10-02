resource "aws_eks_addon" "cloudwatch-observability" {
  cluster_name                = data.aws_ssm_parameter.cluster-name.value
  addon_name                  = "amazon-cloudwatch-observability"
}

resource "aws_eks_addon" "metrics-server" {
  cluster_name                = data.aws_ssm_parameter.cluster-name.value
  addon_name                  = "metrics-server"
}

# new
#resource "aws_eks_addon" "cert-manager" {
#  cluster_name                = data.aws_ssm_parameter.cluster-name.value
#  addon_name                  = "cert-manager"
#}

#resource "aws_eks_addon" "adot" {
#  depends_on                  = [aws_eks_addon.cert-manager]
#  cluster_name                = data.aws_ssm_parameter.cluster-name.value
# addon_name                  = "adot"
#}