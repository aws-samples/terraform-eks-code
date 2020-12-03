resource "aws_vpc_peering_connection" "cicd-peer" {
  peer_vpc_id   = aws_vpc.vpc-mycluster1.id
  vpc_id        = aws_vpc.vpc-cicd.id
  auto_accept   = true
}

output "cicdpeerid" {
  value = aws_vpc_peering_connection.cicd-peer.id
}
