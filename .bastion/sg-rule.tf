resource "aws_security_group_rule" "eks-all" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.vpc-default.cidr_block]
  security_group_id = data.aws_ssm_parameter.net-cluster-sg.value
}