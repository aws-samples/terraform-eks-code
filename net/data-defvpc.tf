# Default VPC Data Source
# Retrieves information about the AWS default VPC in this region
# Used for VPC peering to allow VSCode/Cloud9 access to EKS cluster

data "aws_vpc" "vpc-default" {
  filter {
    name   = "tag:Name"
    values = ["eksworkshop-vpc"]
  }
  cidr_block="172.31.0.0/16"
}


data "aws_route_table" "selected" {
  filter {
    name   = "tag:Name"
    values = ["eksworkshop-Private-Routes"]
  }
}