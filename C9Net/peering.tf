resource "aws_vpc_peering_connection" "foo" {
  peer_vpc_id   = data.terraform_remote_state.net.outputs.eks-vpc
  vpc_id        = data.aws_vpc.vpc-default.id
  auto_accept   = true
}
