# Default VPC Data Source
# Retrieves information about the AWS default VPC
# Used for security group rules to allow VSCode/Cloud9 access

data "aws_vpc" "vpc-default" {
  default = true
}