resource "aws_security_group" "sg-0a1578a53b37b12c6" {
  description = "Communication between the control plane and worker nodegroups"
  vpc_id      = aws_vpc.vpc-mycluster1.id
  tags = {
    "alpha.eksctl.io/cluster-name"                = "mycluster1"
    "alpha.eksctl.io/eksctl-version"              = "0.29.2"
    "Name"                                        = "eksctl-mycluster1-cluster/ControlPlaneSecurityGroup"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = "mycluster1"
  }
}
