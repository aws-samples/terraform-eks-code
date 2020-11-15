resource "aws_route" "route-172-31" {
  route_table_id            = data.aws_route_table.rtb-10-1.id
  destination_cidr_block    = "172.31.0.0/16"
  transit_gateway_id = data.aws_ec2_transit_gateway.mytgw.id
}
