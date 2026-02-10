# Routes from EKS VPC to Default VPC
# Adds routes in EKS VPC route tables to reach default VPC via peering
# Required for bidirectional communication

# Route from private subnets (worker nodes) to default VPC
resource "aws_route" "rt-eks1" {
  # Private subnet route table
  route_table_id            = aws_ssm_parameter.private_rtb.value
  
  # Destination: Default VPC CIDR block
  destination_cidr_block    = data.aws_vpc.vpc-default.cidr_block
  
  # Route via VPC peering connection
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}

# Route from intra subnets (control plane ENIs) to default VPC
resource "aws_route" "rt-eks-isol" {
  # Intra subnet route table
  route_table_id            = aws_ssm_parameter.intra_rtb.value
  
  # Destination: Default VPC CIDR block
  destination_cidr_block    = data.aws_vpc.vpc-default.cidr_block
  
  # Route via VPC peering connection
  vpc_peering_connection_id = aws_vpc_peering_connection.def-peer.id
}

