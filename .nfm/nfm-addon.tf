resource "aws_eks_addon" "example" {
  cluster_name                = data.aws_ssm_parameter.cluster-name.value
  addon_name                  = "aws-network-flow-monitoring-agent"
}