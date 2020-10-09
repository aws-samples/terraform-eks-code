resource "aws_security_group" "sg-04eb791ff13c1a7ba" {
  description = "default VPC security group"
  vpc_id      = aws_vpc.vpc-0528d1e3f0b31cefe.id
}
