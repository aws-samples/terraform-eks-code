data "aws_subnet" "inst-10-1-subnet" {
  id = data.aws_instance.instance-10-1.subnet_id
  vpc_id = data.aws_vpc.vpc-10-1.id
}