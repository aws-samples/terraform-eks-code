
resource "aws_iam_role_policy_attachment" "codebuild-eks-cicd-build-app-service-role__CodeBuildBasePolicy-eks-cicd-build-app" {
  policy_arn = aws_iam_policy.CodeBuildBasePolicy-eks-cicd-build-app.arn
  role       = aws_iam_role.codebuild-eks-cicd-build-app-service-role.id
}
