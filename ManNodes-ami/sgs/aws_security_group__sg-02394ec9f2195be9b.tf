resource "aws_security_group" "sg-02394ec9f2195be9b" {
  description = "Communication between the control plane and worker nodegroups"
  vpc_id      = aws_vpc.vpc-0528d1e3f0b31cefe.id
  tags = {
    "alpha.eksctl.io/eksctl-version"              = "0.28.1"
    "Name"                                        = "eksctl-manamieks-cluster/ControlPlaneSecurityGroup"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = "manamieks"
    "alpha.eksctl.io/cluster-name"                = "manamieks"
  }
}
