resource "aws_security_group_rule" "eks-ssl" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.eks-vpc.cidr_block]
  security_group_id = aws_security_group.cluster-sg.id
}
