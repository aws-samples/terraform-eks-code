resource "aws_iam_user" "git-user" {
  name = "git-user"


  tags = {
    workshop = "eks-cicd"
  }
}