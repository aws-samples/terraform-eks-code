data "aws_subnet" "i1" {
  vpc_id=data.aws_ssm_parameter.eks-vpc.value
    filter {
    name   = "tag:workshop"
    values = ["subnet-i1"]
  }
}

data "aws_subnet" "i2" {
  vpc_id=data.aws_ssm_parameter.eks-vpc.value
    filter {
    name   = "tag:workshop"
    values = ["subnet-i2"]
  }
}


data "aws_subnet" "i3" {
  vpc_id=data.aws_ssm_parameter.eks-vpc.value
  filter {
    name   = "tag:workshop"
    values = ["subnet-i3"]
  }
}