
# aws_iam_policy.CodeBuildBasePolicy-eks-cicd-build-app-eu-west-1:
resource "aws_iam_policy" "CodeBuildBasePolicy-eks-cicd-build-app-eu-west-1" {
  description = "Policy used in trust relationship with CodeBuild"
  name        = "CodeBuildBasePolicy-eks-cicd-build-app-eu-west-1"
  path        = "/service-role/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:logs:eu-west-1:566972129213:log-group:/aws/codebuild/eks-cicd-build-app",
            "arn:aws:logs:eu-west-1:566972129213:log-group:/aws/codebuild/eks-cicd-build-app:*",
          ]
        },
        {
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketAcl",
            "s3:GetBucketLocation",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:s3:::codepipeline-eu-west-1-*",
          ]
        },
        {
          Action = [
            "codecommit:GitPull",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:codecommit:eu-west-1:566972129213:Terraform-EKS",
          ]
        },
        {
          Action = [
            "codebuild:CreateReportGroup",
            "codebuild:CreateReport",
            "codebuild:UpdateReport",
            "codebuild:BatchPutTestCases",
            "codebuild:BatchPutCodeCoverages",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:codebuild:eu-west-1:566972129213:report-group/eks-cicd-build-app-*",
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}
