resource "aws_vpc_peering_connection" "cicd-peer" {
  peer_vpc_id   = data.terraform_remote_state.net.outputs.eks-vpc
  vpc_id        = data.aws_vpc.vpc-cicd.id
  auto_accept   = true
}

output "cicdpeerid" {
  value = aws_vpc_peering_connection.cicd-peer.id
}
