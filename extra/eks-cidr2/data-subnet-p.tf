data "aws_subnet" "p1" {
  vpc_id=data.terraform_remote_state.net.outputs.eks-vpc
    filter {
    name   = "tag:workshop"
    values = ["subnet-p1"]
  }
}

data "aws_subnet" "p2" {
  vpc_id=data.terraform_remote_state.net.outputs.eks-vpc
 
    filter {
    name   = "tag:workshop"
    values = ["subnet-p2"]
  }
}


data "aws_subnet" "p3" {
  vpc_id=data.terraform_remote_state.net.outputs.eks-vpc
  
  filter {
    name   = "tag:workshop"
    values = ["subnet-p3"]
  }
}