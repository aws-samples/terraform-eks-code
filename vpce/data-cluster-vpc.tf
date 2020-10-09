data "aws_vpc" "selected" {
  id = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id
}