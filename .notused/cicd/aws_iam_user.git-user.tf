resource "aws_iam_user" "git-user" {
  name = "git-user"


  tags = {
    workshop = "eks-cicd"
  }
}


resource "aws_iam_user_policy_attachment" "git-attach" {
  user       = aws_iam_user.git-user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitPowerUser"
}