resource "aws_ssm_parameter" "eks-vpc" {
  name        = "/workshop/tf-eks/eks-vpc"
  description = "The EKS cluster VPC id"
  type        = "String"
  value = aws_vpc.cluster.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "eks-cidr" {
  name        = "/workshop/tf-eks/eks-cidr"
  description = "The EKS cluster main CIDR"
  type        = "String"
  value = aws_vpc.cluster.cidr_block
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "sub-isol1" {
  name        = "/workshop/tf-eks/sub-isol1"
  description = "The EKS cluster isolated subnet 1 id"
  type        = "String"
  value = aws_subnet.subnet-i1.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "sub-isol2" {
  name        = "/workshop/tf-eks/sub-isol2"
  description = "The EKS cluster isolated subnet 2 id"
  type        = "String"
  value = aws_subnet.subnet-i2.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "sub-isol3" {
  name        = "/workshop/tf-eks/sub-isol3"
  description = "The EKS cluster isolated subnet 3 id"
  type        = "String"
  value = aws_subnet.subnet-i3.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "sub-p1" {
  name        = "/workshop/tf-eks/sub-p1"
  description = "The EKS cluster private subnet 1 id"
  type        = "String"
  value = aws_subnet.subnet-p1.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "sub-priv1" {
  name        = "/workshop/tf-eks/sub-priv1"
  description = "The EKS cluster private subnet 1 id"
  type        = "String"
  value = aws_subnet.subnet-p1.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "sub-priv2" {
  name        = "/workshop/tf-eks/sub-priv2"
  description = "The EKS cluster private subnet 2 id"
  type        = "String"
  value = aws_subnet.subnet-p2.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "sub-priv3" {
  name        = "/workshop/tf-eks/sub-priv3"
  description = "The EKS cluster private subnet 3 id"
  type        = "String"
  value = aws_subnet.subnet-p1.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}



resource "aws_ssm_parameter" "cicd-vpc" {
  name        = "/workshop/tf-eks/cicd-vpc"
  description = "The cicd vpc id"
  type        = "String"
  value = aws_vpc.vpc-cicd.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "cicd-cidr" {
  name        = "/workshop/tf-eks/cicd-cidr"
  description = "The cicd cidr block"
  type        = "String"
  value = aws_vpc.vpc-cicd.cidr_block
  tags = {
    workshop = "tf-eks-workshop"
  }
}


resource "aws_ssm_parameter" "net-cluster-sg" {
  name        = "/workshop/tf-eks/net-cluster-sg"
  description = "The cluster security group id"
  type        = "String"
  value = aws_security_group.cluster-sg.id
  tags = {
    workshop = "tf-eks-workshop"
  }

}

resource "aws_ssm_parameter" "allnodes-sg" {
  name        = "/workshop/tf-eks/allnodes-sg"
  description = "The cluster all node group id"
  type        = "String"
  value = aws_security_group.allnodes-sg.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}


resource "aws_ssm_parameter" "rtb-isol" {
  name        = "/workshop/tf-eks/rtb-isol"
  description = "Isol route table id"
  type        = "String"
  value = aws_route_table.rtb-i.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

resource "aws_ssm_parameter" "rtb-priv1" {
  name        = "/workshop/tf-eks/rtb-priv1"
  description = "Priv route table id 1"
  type        = "String"
  value = aws_route_table.rtb-p1.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}


resource "aws_ssm_parameter" "rtb-priv2" {
  name        = "/workshop/tf-eks/rtb-priv2"
  description = "Priv route table id 2"
  type        = "String"
  value = aws_route_table.rtb-p2.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}


resource "aws_ssm_parameter" "rtb-priv3" {
  name        = "/workshop/tf-eks/rtb-priv3"
  description = "Priv route table id 3"
  type        = "String"
  value = aws_route_table.rtb-p3.id
  tags = {
    workshop = "tf-eks-workshop"
  }
}







