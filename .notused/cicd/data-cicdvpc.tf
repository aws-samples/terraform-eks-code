data "aws_vpc" "cicd" {
  default = false
  filter {
    name   = "tag:workshop"
    values = ["eks-cicd"]
  }
}
