data "aws_eks_cluster" "eks_cluster" {
  name = data.aws_ssm_parameter.cluster-name.value
}
