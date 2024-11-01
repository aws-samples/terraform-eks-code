resource "aws_vpc_peering_connection" "def-peer" {
  peer_vpc_id = module.vpc.vpc_id
  vpc_id      = data.aws_vpc.vpc-default.id
  auto_accept = true
}

output "peerid" {
  value = aws_vpc_peering_connection.def-peer.id
}
