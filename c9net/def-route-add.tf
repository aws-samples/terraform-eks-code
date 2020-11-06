resource "aws_route" "rt-def" {
  route_table_id            = data.aws_vpc.vpc-default.main_route_table_id
  destination_cidr_block    = data.terraform_remote_state.net.outputs.eks-cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}