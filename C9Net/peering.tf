resource "aws_vpc_peering_connection" "foo" {
  peer_vpc_id   = aws_vpc.bar.id
  vpc_id        = aws_vpc.vpc-default.id
  auto_accept   = true
}
