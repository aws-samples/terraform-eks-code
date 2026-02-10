# VPC Peering Connection
# Creates peering between default VPC and EKS VPC
# Allows VSCode/Cloud9 instance to access EKS cluster for kubectl commands

resource "aws_vpc_peering_connection" "def-peer" {
  # EKS VPC (peer)
  peer_vpc_id = module.vpc.vpc_id
  
  # Default VPC (requester)
  vpc_id      = data.aws_vpc.vpc-default.id
  
  # Auto-accept since both VPCs are in same account
  auto_accept = true
}

# Output peering connection ID for use in route configuration
output "peerid" {
  value = aws_vpc_peering_connection.def-peer.id
}
