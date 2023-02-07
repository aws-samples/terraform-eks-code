resource "aws_iam_policy" "eks-fargate-logging-policy" {
  name        = format("eks-fargate-log-policy-%s",data.aws_ssm_parameter.tf-eks-id.value)
  path        = "/"
  description = "eks-fargate-logging-policy"
  policy = file("logging-permissions.json")
}