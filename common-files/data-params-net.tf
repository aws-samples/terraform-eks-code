data "aws_ssm_parameter" "eks-vpc" {
  name        = "/workshop/tf-eks/eks-vpc"
}

data "aws_ssm_parameter" "eks-cidr" {
  name        = "/workshop/tf-eks/eks-cidr"
}

data "aws_ssm_parameter" "sub-isol1" {
  name        = "/workshop/tf-eks/sub-isol1"
}

data "aws_ssm_parameter" "sub-isol2" {
  name        = "/workshop/tf-eks/sub-isol2"
}

data "aws_ssm_parameter" "sub-isol3" {
  name        = "/workshop/tf-eks/sub-isol3"
}

data "aws_ssm_parameter" "sub-p1" {
  name        = "/workshop/tf-eks/sub-p1"
}

data "aws_ssm_parameter" "sub-priv1" {
  name        = "/workshop/tf-eks/sub-priv1"
}

data "aws_ssm_parameter" "sub-priv2" {
  name        = "/workshop/tf-eks/sub-priv2"
}

data "aws_ssm_parameter" "sub-priv3" {
  name        = "/workshop/tf-eks/sub-priv3"
}

data "aws_ssm_parameter" "cicd-vpc" {
  name        = "/workshop/tf-eks/cicd-vpc"
}

data "aws_ssm_parameter" "cicd-cidr" {
  name        = "/workshop/tf-eks/cicd-cidr"
}


data "aws_ssm_parameter" "net-cluster-sg" {
  name        = "/workshop/tf-eks/net-cluster-sg"
}

data "aws_ssm_parameter" "allnodes-sg" {
  name        = "/workshop/tf-eks/allnodes-sg"
}


data "aws_ssm_parameter" "rtb-isol" {
  name        = "/workshop/tf-eks/rtb-isol"
}

data "aws_ssm_parameter" "rtb-priv1" {
  name        = "/workshop/tf-eks/rtb-priv1"
}


data "aws_ssm_parameter" "rtb-priv2" {
  name        = "/workshop/tf-eks/rtb-priv2"
}


data "aws_ssm_parameter" "rtb-priv3" {
  name        = "/workshop/tf-eks/rtb-priv3"
}







