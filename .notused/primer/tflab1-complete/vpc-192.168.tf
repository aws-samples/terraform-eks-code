resource "aws_vpc" "VPC-192-168" {
  assign_generated_ipv6_cidr_block = false
  cidr_block                       = "192.168.0.0/16"
  enable_dns_hostnames             = false
  enable_dns_support               = true
  instance_tenancy                 = "default"
  tags = {
    "Name" = "VPC-192-168"
  }
}