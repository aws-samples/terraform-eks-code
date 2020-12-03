resource "aws_route" "rt-eks1" {
  route_table_id            = aws_route_table.rtb-041267f0474c24068.id
  destination_cidr_block    = data.aws_vpc.vpc-default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}

resource "aws_route" "rt-eks2" {
  route_table_id            = aws_route_table.rtb-0102c621469c344cd.id
  destination_cidr_block    = data.aws_vpc.vpc-default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}

resource "aws_route" "rt-eks3" {
  route_table_id            = aws_route_table.rtb-0329e787bbafcb2c4.id
  destination_cidr_block    = data.aws_vpc.vpc-default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}

resource "aws_route" "rt-eks4" {
  route_table_id            = aws_route_table.rtb-041267f0474c24068.id
  destination_cidr_block    = aws_vpc.vpc-cicd.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cicd-peer.id
}

resource "aws_route" "rt-eks5" {
  route_table_id            = aws_route_table.rtb-0102c621469c344cd.id
  destination_cidr_block    = aws_vpc.vpc-cicd.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cicd-peer.id
}

resource "aws_route" "rt-eks6" {
  route_table_id            = aws_route_table.rtb-0329e787bbafcb2c4.id
  destination_cidr_block    = aws_vpc.vpc-cicd.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cicd-peer.id
}