resource "aws_subnet" "myprivsubnet" {
  assign_ipv6_address_on_creation = false
  availability_zone               = data.aws_availability_zones.az.names[0]
  cidr_block                      = "192.168.4.0/24"
  map_public_ip_on_launch         = false
  tags = {
    "Name" = "Private subnet 192.168"
  }
  vpc_id = aws_vpc.VPC-192-168.id

  timeouts {}
}

resource "aws_subnet" "mypubsubnet" {
  assign_ipv6_address_on_creation = false
  availability_zone               = data.aws_availability_zones.az.names[0]
  cidr_block                      = "192.168.1.0/24"
  map_public_ip_on_launch         = false
  tags = {
    "Name" = "Public subnet 192.168"
  }
  vpc_id = aws_vpc.VPC-192-168.id

  timeouts {}
}