resource "aws_ssm_parameter" "cluster_service_role_arn" {
  name        = "/workshop/tf-eks/cluster_service_role_arn"
  description = "cluster service role arn"
  type        = "String" 
  value = aws_iam_role.eks-cluster-ServiceRole.arn  
  tags = {
    workshop = "tf-eks-workshop"
  }
}


resource "aws_ssm_parameter" "nodegroup_role_arn" {
  name        = "/workshop/tf-eks/nodegroup_role_arn"
  description = "node grpup role arn"
  type        = "String"
  value = aws_iam_role.eks-nodegroup-ng-ma-NodeInstanceRole.arn
  tags = {
    workshop = "tf-eks-workshop"
  }
}



resource "aws_ssm_parameter" "key_name" {
  name        = "/workshop/tf-eks/key_name"
  description = "ssh key pair name"
  type        = "String"    
  value = aws_key_pair.eksworkshop.key_name
  tags = {
    workshop = "tf-eks-workshop"
  }
}
