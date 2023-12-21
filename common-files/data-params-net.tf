data "aws_ssm_parameter" "eks-vpc" {
  name        = "/workshop/tf-eks/eks-vpc"
}

data "aws_ssm_parameter" "eks-cidr" {
  name        = "/workshop/tf-eks/eks-cidr"
}

data "aws_ssm_parameter" "cicd-cidr" {
  name        = "/workshop/tf-eks/cicd-cidr"
}

data "aws_ssm_parameter" "cicd-vpc" {
  name        = "/workshop/tf-eks/cicd-vpc"
}

data "aws_ssm_parameter" "private_subnets" {
  name        = "/workshop/tf-eks/private_subnets"
}  

data "aws_ssm_parameter" "intra_subnets" {
  name        = "/workshop/tf-eks/intra_subnets"
}  

data "aws_ssm_parameter" "private_rtb" {
  name        = "/workshop/tf-eks/private_rtb"
} 

data "aws_ssm_parameter" "intra_rtb" {
  name        = "/workshop/tf-eks/intra_rtb"
} 

data "aws_ssm_parameter" "public_rtb" {
  name        = "/workshop/tf-eks/public_rtb"
} 

data "aws_ssm_parameter" "phz-id" {
  name        = "/workshop/tf-eks/phz-id"
} 






