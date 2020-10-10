data "aws_subnet_ids" "private" {
    vpc_id = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id
    filter {
        name   = "tag:kubernetes.io/role/internal-elb"
        values = ["1"] # insert values here
    }
}

data "aws_subnet" "example" {
  for_each = data.aws_subnet_ids.private.ids
  id       = each.value
}



