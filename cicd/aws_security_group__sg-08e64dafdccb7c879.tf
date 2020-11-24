resource "aws_security_group" "sg-08e64dafdccb7c879" {
  description = "eks-cicd all"
  vpc_id      = aws_vpc.vpc-026635e1e91a07ddd.id
  tags = {
    "Name"     = "eks-cicd-all"
    "workshop" = "eks-cicd"
  }
}
