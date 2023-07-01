data "aws_ssm_parameter" "cluster_service_role_arn" {
  name        = "/workshop/tf-eks/cluster_service_role_arn"
}

data "aws_ssm_parameter" "nodegroup_role_arn" {
  name        = "/workshop/tf-eks/nodegroup_role_arn"
}

data "aws_ssm_parameter" "key_name" {
  name        = "/workshop/tf-eks/key_name"
}
