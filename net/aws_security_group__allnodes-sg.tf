resource "aws_security_group" "allnodes-sg" {
  description = "Communication between all nodes in the cluster"
  vpc_id      = aws_vpc.cluster.id
  tags = {
    "Name"   = format("eks-%s-cluster/ClusterSharedNodeSecurityGroup",var.cluster-name)
    "Label"  = "TF-EKS All Nodes Comms"
  }
}

output "allnodes-sg" {
  value = aws_security_group.allnodes-sg.id
}