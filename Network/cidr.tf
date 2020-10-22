resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.vpc-0528d1e3f0b31cefe.id
  cidr_block = "100.64.0.0/16"
}