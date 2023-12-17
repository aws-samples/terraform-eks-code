resource "aws_route" "rt-cicd" {
  route_table_id            = data.aws_route_table.cicd-rtb.id
  destination_cidr_block    = data.aws_ssm_parameter.eks-cidr.value
  vpc_peering_connection_id = aws_vpc_peering_connection.cicd-peer.id
}

resource "aws_route" "rt-def-cicd" {
  route_table_id            = data.aws_vpc.vpc-cicd.main_route_table_id
  destination_cidr_block    = data.aws_ssm_parameter.eks-cidr.value
  vpc_peering_connection_id = aws_vpc_peering_connection.cicd-peer.id
}