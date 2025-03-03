resource "aws_eks_addon" "cloudwatch-observability" {
  cluster_name                = data.aws_ssm_parameter.cluster-name.value
  addon_name                  = "amazon-cloudwatch-observability"
}

resource "aws_eks_addon" "metrics-server" {
  cluster_name                = data.aws_ssm_parameter.cluster-name.value
  addon_name                  = "metrics-server"
}