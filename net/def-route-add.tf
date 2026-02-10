# Route from Default VPC to EKS VPC
# Adds route in default VPC's main route table to reach EKS VPC via peering
# Enables VSCode/Cloud9 instance to communicate with EKS cluster

resource "aws_route" "rt-def" {
  # Default VPC's main route table
  route_table_id            = data.aws_vpc.vpc-default.main_route_table_id
  
  # Destination: EKS VPC CIDR block
  destination_cidr_block    = module.vpc.vpc_cidr_block
  
  # Route via VPC peering connection
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}