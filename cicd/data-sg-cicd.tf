data "aws_security_group" "cicd" {
  vpc_id=data.aws_vpc.cicd.id
  filter {
    name   = "tag:workshop"
    values = ["eks-cicd"]
  }
}







