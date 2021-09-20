
# aws_iam_policy.CodeBuildBasePolicy-eks-cicd-build-app:
resource "aws_iam_policy" "CodeBuildBasePolicy-eks-cicd-build-app" {
  description = "Policy used in trust relationship with CodeBuild v0.4"
  name        = "CodeBuildBasePolicy-eks-cicd-build-app"
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
             format("arn:aws:logs:%s:%s:log-group:/aws/codebuild/eks-cicd-build-app",data.aws_region.current.name,data.aws_caller_identity.current.account_id),
             format("arn:aws:logs:%s:%s:log-group:/aws/codebuild/eks-cicd-build-app:*", data.aws_region.current.name,data.aws_caller_identity.current.account_id)
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
            format("arn:aws:s3:::codepipeline-%s-*",data.aws_region.current.name)
          ]
        },
        {
          Action = [
            "codecommit:GitPull",
          ]
          Effect = "Allow"
          Resource = [
            format("arn:aws:codecommit:%s:%s:Terraform-EKS", data.aws_region.current.name,data.aws_caller_identity.current.account_id),
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
            #format("arn:aws:codebuild:%s:%s:report-group/eks-cicd-build-app-*",data.aws_caller_identity.current.account_id, data.aws_region.current.name),
            format("arn:aws:codebuild:%s:%s:report-group/eks-cicd-build-app-*",data.aws_region.current.name,data.aws_caller_identity.current.account_id),
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}
