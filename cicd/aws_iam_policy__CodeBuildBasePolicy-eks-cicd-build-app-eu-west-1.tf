
# aws_iam_policy.CodeBuildBasePolicy-eks-cicd-build-app:
resource "aws_iam_policy" "CodeBuildBasePolicy-eks-cicd-build-app" {
  description = "Policy used in trust relationship with CodeBuild"
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
             format("arn:aws:logs:%s:%s:log-group:/aws/codebuild/eks-cicd-build-app",data.aws_caller_identity.current.account_id, data.aws_region.current.name),
             format("arn:aws:logs:%s:%s:log-group:/aws/codebuild/eks-cicd-build-app:*",data.aws_caller_identity.current.account_id, data.aws_region.current.name)
#            "arn:aws:logs:eu-west-1:566972129213:log-group:/aws/codebuild/eks-cicd-build-app",
#            "arn:aws:logs:eu-west-1:566972129213:log-group:/aws/codebuild/eks-cicd-build-app:*",
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
            format("arn:aws:codebuild:%s:%s:report-group/eks-cicd-build-app-*",data.aws_caller_identity.current.account_id, data.aws_region.current.name),
            #"arn:aws:codebuild:eu-west-1:566972129213:report-group/eks-cicd-build-app-*",
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}
