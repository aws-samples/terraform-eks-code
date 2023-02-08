data "aws_ssm_parameter" "tf-eks-id" {
  name = "/workshop/tf-eks/id"
}

data "aws_ssm_parameter" "tf-eks-keyid" {
  name = "/workshop/tf-eks/keyid"
}

data "aws_ssm_parameter" "tf-eks-keyarn" {
  name = "/workshop/tf-eks/keyarn"
}

data "aws_ssm_parameter" "tf-eks-region" {
  name = "/workshop/tf-eks/region"
}

data "aws_ssm_parameter" "tf-eks-cluster-name" {
  name = "/workshop/tf-eks/cluster-name"
}

data "aws_ssm_parameter" "tf-eks-version" {
  name = "/workshop/tf-eks/eks-version"
}