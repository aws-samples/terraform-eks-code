data "aws_security_group" "cicd-sg" {
  vpc_id=data.aws_vpc.vpc-cicd.id
  filter {
    name   = "tag:workshop"
    values = ["eks-cicd"]
  }
}







