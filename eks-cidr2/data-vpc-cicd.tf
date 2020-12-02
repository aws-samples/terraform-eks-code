data "aws_vpc" "vpc-cicd" {
    filter {
    name   = "tag:workshop"
    values = ["eks-cicd"]
  }
}
