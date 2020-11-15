data "aws_instance" "c9" {
filter {
    name = "vpc-id"
    values = [data.aws_vpc.dvpc.id]
}
}