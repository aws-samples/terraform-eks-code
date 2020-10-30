data "aws_vpc" "vpc-default" {
  default = true
}

output "def-rtb" {
  value       = data.aws_vpc.vpc-default.main_route_table_id
  description = "The default route table"
}

output "def-cidr" {
  value       = data.aws_vpc.vpc-default.cidr_block
  description = "The default route table"
}