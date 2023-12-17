resource "aws_route" "rt-eks1" {
  route_table_id            = data.aws_ssm_parameter.private_rtb.value
  destination_cidr_block    = data.aws_vpc.vpc-default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}

resource "aws_route" "rt-eks-isol" {
  route_table_id            = data.aws_ssm_parameter.intra_rtb.value
  destination_cidr_block    = data.aws_vpc.vpc-default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}

