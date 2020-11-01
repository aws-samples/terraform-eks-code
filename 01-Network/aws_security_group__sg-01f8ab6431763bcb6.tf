resource "aws_security_group" "sg-01f8ab6431763bcb6" {
  description = "EKS created security group applied to ENI that is attached to EKS Control Plane master nodes, as well as any managed workloads."
  vpc_id      = aws_vpc.vpc-mycluster1.id
  tags = {
    "Name"                             = "eks-cluster-sg-mycluster1-1624744410"
    "kubernetes.io/cluster/mycluster1" = "owned"
    "Label"                            = "TF-EKS Control Plane + Managed node ENI's"
  }
}
