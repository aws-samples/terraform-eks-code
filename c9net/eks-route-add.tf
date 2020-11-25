resource "aws_route" "rt-eks1" {
  route_table_id            = data.terraform_remote_state.net.outputs.rtb-priv1
  destination_cidr_block    = data.aws_vpc.vpc-default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}

resource "aws_route" "rt-eks2" {
  route_table_id            = data.terraform_remote_state.net.outputs.rtb-priv2
  destination_cidr_block    = data.aws_vpc.vpc-default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}

resource "aws_route" "rt-eks3" {
  route_table_id            = data.terraform_remote_state.net.outputs.rtb-priv3
  destination_cidr_block    = data.aws_vpc.vpc-default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}

resource "aws_route" "rt-eks4" {
  route_table_id            = data.terraform_remote_state.net.outputs.rtb-priv1
  destination_cidr_block    = data.aws_vpc.vpc-cicd.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cicd-peer.id
}

resource "aws_route" "rt-eks5" {
  route_table_id            = data.terraform_remote_state.net.outputs.rtb-priv2
  destination_cidr_block    = data.aws_vpc.vpc-cicd.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cicd-peer.id
}

resource "aws_route" "rt-eks6" {
  route_table_id            = data.terraform_remote_state.net.outputs.rtb-priv3
  destination_cidr_block    = data.aws_vpc.vpc-cicd.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cicd-peer.id
}