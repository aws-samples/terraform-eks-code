
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
  type        = "String"
  value = element(module.vpc.private_route_table_ids,0)
  tags = {
    workshop = "tf-eks-workshop"
  }
} 

resource "aws_ssm_parameter" "intra_rtb" {
name        = "/workshop/tf-eks/intra_rtb"
  description = "The intra route table id for cluster"
  type        = "String"
  value = element(module.vpc.intra_route_table_ids,0)
  tags = {
    workshop = "tf-eks-workshop"
  }
} 

resource "aws_ssm_parameter" "public_rtb" {
name        = "/workshop/tf-eks/public_rtb"
  description = "The public route table id for cluster"
  type        = "String"
  value = element(module.vpc.public_route_table_ids,0)
  tags = {
    workshop = "tf-eks-workshop"
  }
} 

resource "aws_ssm_parameter" "phz-id" {
name        = "/workshop/tf-eks/phz-id"
  description = "The id for private hosted zone"
  type        = "String"
  value = aws_route53_zone.resource local_file name {
    sensitive_content = ""
    filename             = "${path.module}/files/outputfile"
    file_permission      = 0777
    directory_permission = 0777
  }
  .id
tags = {
    workshop = "tf-eks-workshop"
  }
} 
