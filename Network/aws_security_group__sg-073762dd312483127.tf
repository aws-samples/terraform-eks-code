resource "aws_security_group" "sg-073762dd312483127" {
  description = "Communication between all nodes in the cluster"
  vpc_id      = aws_vpc.vpc-mycluster1.id
  tags = {
    "alpha.eksctl.io/cluster-name"                = "mycluster1"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = "mycluster1"
    "Name"                                        = "eksctl-mycluster1-cluster/ClusterSharedNodeSecurityGroup"
    "alpha.eksctl.io/eksctl-version"              = "0.29.2"
  }
}

output "allnodes-sg" {
  value = aws_security_group.sg-073762dd312483127.id
}