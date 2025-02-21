resource "aws_route" "rt-eks1" {
  route_table_id            = aws_ssm_parameter.private_rtb.value
  destination_cidr_block    = data.aws_vpc.vpc-default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}

resource "aws_route" "nat-ipv6" {
  route_table_id            = aws_ssm_parameter.private_rtb.value
  destination_ipv6_cidr_block    = "::/0"
  net_gateway_id = module.vpc.natgw_ids[0]
}

resource "aws_route" "nat-ipv4" {
  route_table_id            = aws_ssm_parameter.private_rtb.value
  destination_ipv6_cidr_block    = "0.0.0.0/0"
  net_gateway_id = module.vpc.natgw_ids[0]
}


resource "aws_route" "rt-eks-isol" {
  route_table_id            = aws_ssm_parameter.intra_rtb.value
  destination_cidr_block    = data.aws_vpc.vpc-default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}

