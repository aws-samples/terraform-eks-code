resource "aws_security_group" "sg-0e4cf06a65fca2cb8" {
  description = "Communication between all nodes in the cluster"
  vpc_id      = aws_vpc.vpc-0528d1e3f0b31cefe.id
  tags = {
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = "manamieks"
    "alpha.eksctl.io/cluster-name"                = "manamieks"
    "Name"                                        = "eksctl-manamieks-cluster/ClusterSharedNodeSecurityGroup"
    "alpha.eksctl.io/eksctl-version"              = "0.28.1"
  }
}
