data "aws_vpc" "vpc-cicd" {
  default = false
  filter {
    name   = "tag:workshop"
    values = ["eks-cicd"]
  }
}
