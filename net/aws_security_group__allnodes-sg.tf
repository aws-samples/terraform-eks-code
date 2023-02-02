resource "aws_security_group" "allnodes-sg" {
  description = "Communication between all nodes in the cluster"
  vpc_id      = aws_vpc.cluster.id
  tags = {
    "Name"  = format("eks-%s-cluster/ClusterSharedNodeSecurityGroup", data.aws_ssm_parameter.tf-eks-cluster-name.value)
    "Label" = "TF-EKS All Nodes Comms"
  }
}

output "allnodes-sg" {
  value = aws_security_group.allnodes-sg.id
}