resource "aws_route" "route-10-0" {
  route_table_id            = data.aws_route_table.defrt.id
  destination_cidr_block    = "10.0.0.0/8"
  transit_gateway_id = data.aws_ec2_transit_gateway.mytgw.id
}

