resource "aws_security_group_rule" "eks-all" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.vpc-default.cidr_block]
  security_group_id = data.terraform_remote_state.net.outputs.cluster-sg
}

resource "aws_security_group_rule" "eks-node" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.vpc-default.cidr_block]
  security_group_id = data.terraform_remote_state.net.outputs.allnodes-sg
}

resource "aws_security_group_rule" "eks-all-node" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  source_security_group_id = data.terraform_remote_state.net.outputs.allnodes-sg
  security_group_id = data.terraform_remote_state.net.outputs.cluster-sg
}

resource "aws_security_group_rule" "eks-node-all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  source_security_group_id = data.terraform_remote_state.net.outputs.cluster-sg
  security_group_id = data.terraform_remote_state.net.outputs.allnodes-sg
}

#resource "aws_security_group_rule" "eks-all-self" {
#  type              = "ingress"
#  self = true
#  security_group_id = data.terraform_remote_state.net.outputs.cluster-sg
#}
#resource "aws_security_group_rule" "eks-node-self" {
#  type              = "ingress"
#  self = true
#  security_group_id = data.terraform_remote_state.net.outputs.allnodes-sg
#}