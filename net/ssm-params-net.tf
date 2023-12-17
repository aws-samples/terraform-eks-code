
resource "aws_ssm_parameter" "cicd-vpc" {
  name        = "/workshop/tf-eks/cicd-vpc"
  description = "The cicd vpc id"
  type        = "String"
  value = module.vpc.vpc_id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "eks-vpc" {
  name        = "/workshop/tf-eks/eks-vpc"
  description = "The eks vpc id"
  type        = "String"
  value = module.vpc.vpc_id
  tags = {
    workshop = "tf-eks-workshop"
  }
}


resource "aws_ssm_parameter" "eks-cidr" {
  name        = "/workshop/tf-eks/eks-cidr"
  description = "The EKS cluster main CIDR"
  type        = "String"
  value = module.vpc.vpc_cidr_block
  tags = {
    workshop = "tf-eks-workshop"
  }
}


resource "aws_ssm_parameter" "cicd-cidr" {
  name        = "/workshop/tf-eks/cicd-cidr"
  description = "The cicd cidr block"
  type        = "String"
  value = module.vpc.vpc_cidr_block
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "private_subnets" {
name        = "/workshop/tf-eks/private_subnets"
  description = "The private subnets for cluster"
  type        = "StringList"
  value = jsonencode(module.vpc.private_subnets)
  tags = {
    workshop = "tf-eks-workshop"
  }
}  

resource "aws_ssm_parameter" "intra_subnets" {
name        = "/workshop/tf-eks/intra_subnets"
  description = "The intra subnets for cluster"
  type        = "StringList"
  value = jsonencode(module.vpc.intra_subnets)
  tags = {
    workshop = "tf-eks-workshop"
  }
}  

resource "aws_ssm_parameter" "private_rtb" {
name        = "/workshop/tf-eks/private_rtb"
  description = "The private route table id for cluster"
  type        = "StringList"
  value = jsonencode(module.vpc.private_route_table_ids)
  tags = {
    workshop = "tf-eks-workshop"
  }
} 



