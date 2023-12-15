resource "aws_security_group" "eks-cicd-sg" {
  description = "eks-cicd all"
  vpc_id      = aws_vpc.vpc-cicd.id
  tags = {
    "Name"     = "eks-cicd-all"
    "workshop" = "eks-cicd"
  }
}
