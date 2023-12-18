resource "aws_security_group_rule" "eks-all" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.vpc-default.cidr_block]
  security_group_id = module.eks.cluster_primary_security_group_id
}

resource "aws_security_group_rule" "eks-all-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = module.eks.cluster_primary_security_group_id
  cidr_blocks       = [data.aws_vpc.vpc-default.cidr_block]
}



#resource "aws_security_group_rule" "eks-all-self" {
#  type              = "ingress"
#  from_port         = 0
#  to_port           = 0
#  protocol          = "-1"
#  self              = true
#  security_group_id = data.aws_ssm_parameter.net-cluster-sg.value
#}