resource "aws_security_group_rule" "sg-def-22" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.net.outputs.eks-cidr]
  security_group_id = data.aws_security_group.c9sg.id
}

resource "aws_security_group_rule" "sg-def-eks-all" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.net.outputs.eks-cidr]
  security_group_id = data.aws_security_group.c9sg.id
}