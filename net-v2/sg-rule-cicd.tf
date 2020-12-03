resource "aws_security_group_rule" "sg-cicd-22" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.vpc-mycluster1.cidr_block]
  security_group_id = aws_security_group.eks-cicd-sg.id
}

resource "aws_security_group_rule" "sg-cicd-eks-all" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.vpc-mycluster1.cidr_block]
  security_group_id = aws_security_group.eks-cicd-sg.id
}

resource "aws_security_group_rule" "sg-cicd-self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self = true
  security_group_id = aws_security_group.eks-cicd-sg.id
}

resource "aws_security_group_rule" "sg-cicd-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks-cicd-sg.id
}