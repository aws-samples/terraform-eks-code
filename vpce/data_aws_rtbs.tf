data "aws_route_tables" "rts" {
  vpc_id = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}
