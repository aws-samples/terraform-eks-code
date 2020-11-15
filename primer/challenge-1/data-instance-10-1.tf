data "aws_instance" "instance-10-1" {
filter {
    name = "vpc-id"
    values = [data.aws_vpc.vpc-10-1.id]
}
}