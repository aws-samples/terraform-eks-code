data "aws_subnet_ids" "private" {
  vpc_id = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id

}