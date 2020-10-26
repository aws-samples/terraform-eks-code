resource "aws_security_group" "sg-0527f649dc9508220" {
  description = "default VPC security group"
  vpc_id      = aws_vpc.vpc-mycluster1.id
}
