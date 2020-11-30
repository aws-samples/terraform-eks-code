
# aws_iam_role_policy_attachment.codebuild-eks-cicd-build-app-service-role__AdministratorAccess:
resource "aws_iam_role_policy_attachment" "codebuild-eks-cicd-build-app-service-role__AdministratorAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.codebuild-eks-cicd-build-app-service-role.id
}
