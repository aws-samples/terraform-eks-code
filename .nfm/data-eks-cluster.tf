data "aws_eks_cluster" "eksworkshop" {
  name = data.aws_ssm_parameter.cluster-name.value
}