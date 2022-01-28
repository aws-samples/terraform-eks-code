resource "aws_iam_policy" "eks-fargate-logging-policy" {
  name        = format("eks-fargate-log-policy-%s",var.tfid)
  path        = "/"
  description = "eks-fargate-logging-policy"

  policy = file("logging-permissions.json")
  
}