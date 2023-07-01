data "aws_ssm_parameter" "oidc_provider_arn" {
  name        = "/workshop/tf-eks/oidc_provider_arn"
}

data "aws_ssm_parameter" "cluster-name" {
  name        = "/workshop/tf-eks/cluster-name"
}

data "aws_ssm_parameter" "cluster-sg" {
  name        = "/workshop/tf-eks/cluster-sg"
}

data "aws_ssm_parameter" "ca" {
  name        = "/workshop/tf-eks/ca"
}

data "aws_ssm_parameter" "endpoint" {
  name        = "/workshop/tf-eks/endpoint"
}
