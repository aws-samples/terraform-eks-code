data "aws_subnet" "c9subnet" {
  id = data.aws_instance.c9.subnet_id
  vpc_id = data.aws_vpc.dvpc.id
}