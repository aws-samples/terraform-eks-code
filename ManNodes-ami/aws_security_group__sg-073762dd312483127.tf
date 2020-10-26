resource "aws_security_group" "sg-073762dd312483127" {
  description = "Communication between all nodes in the cluster"
  vpc_id      = aws_vpc.vpc-0c5887ebf50affcd7.id
  tags = {
    "alpha.eksctl.io/cluster-name"                = "manamieksp"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = "manamieksp"
    "Name"                                        = "eksctl-manamieksp-cluster/ClusterSharedNodeSecurityGroup"
    "alpha.eksctl.io/eksctl-version"              = "0.29.2"
  }
}
