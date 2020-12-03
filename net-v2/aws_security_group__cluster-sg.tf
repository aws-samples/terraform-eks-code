resource "aws_security_group" "cluster-sg" {
  description = "Communication between the control plane and worker nodegroups"
  vpc_id      = aws_vpc.vpc-mycluster1.id
  tags = {
   # "alpha.eksctl.io/cluster-name"                = "mycluster1"
   # "alpha.eksctl.io/eksctl-version"              = "0.29.2"
    "Name"                                        = "eksctl-mycluster1-cluster/ControlPlaneSecurityGroup"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = "mycluster1"
    "Label"                            = "TF-EKS Control Plane & all worker nodes comms"
  }
}

output "cluster-sg" {
  value = aws_security_group.cluster-sg.id
}
