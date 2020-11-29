resource "aws_security_group_rule" "eks-all" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.vpc-default.cidr_block]
  security_group_id = data.terraform_remote_state.net.outputs.cluster-sg
}

resource "aws_security_group_rule" "eks-all-cicd" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.vpc-cicd.cidr_block]
  security_group_id = data.terraform_remote_state.net.outputs.cluster-sg
}

resource "aws_security_group_rule" "eks-all-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = data.terraform_remote_state.net.outputs.cluster-sg
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "eks-node" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.vpc-default.cidr_block]
  security_group_id = data.terraform_remote_state.net.outputs.allnodes-sg
}


resource "aws_security_group_rule" "eks-node-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = data.terraform_remote_state.net.outputs.allnodes-sg
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "eks-all-node" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = data.terraform_remote_state.net.outputs.allnodes-sg
  security_group_id = data.terraform_remote_state.net.outputs.cluster-sg
}

resource "aws_security_group_rule" "eks-node-all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = data.terraform_remote_state.net.outputs.cluster-sg
  security_group_id = data.terraform_remote_state.net.outputs.allnodes-sg
}

resource "aws_security_group_rule" "eks-all-self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self = true
  security_group_id = data.terraform_remote_state.net.outputs.cluster-sg
}

resource "aws_security_group_rule" "eks-node-self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self = true
  security_group_id = data.terraform_remote_state.net.outputs.allnodes-sg
}