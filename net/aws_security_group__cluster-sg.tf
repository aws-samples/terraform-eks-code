resource "aws_security_group" "cluster-sg" {
  description = "Communication between the control plane and worker nodegroups"
  vpc_id      = aws_vpc.cluster.id
  tags = {
    "Name" = format("eks-%s-cluster/ControlPlaneSecurityGroup",var.cluster-name)
    "Label" = "TF-EKS Control Plane & all worker nodes comms"
  }
}

output "cluster-sg" {
  value = aws_security_group.cluster-sg.id
}
