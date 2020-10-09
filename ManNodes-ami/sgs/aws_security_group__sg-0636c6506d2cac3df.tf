resource "aws_security_group" "sg-0636c6506d2cac3df" {
  description = "EKS created security group applied to ENI that is attached to EKS Control Plane master nodes, as well as any managed workloads."
  vpc_id      = aws_vpc.vpc-0528d1e3f0b31cefe.id
  tags = {
    "kubernetes.io/cluster/manamieks" = "owned"
    "Name"                            = "eks-cluster-sg-manamieks-468053110"
  }
}
