
# aws_iam_policy.CodeBuildVpcPolicy-eks-cicd-build-app:
resource "aws_iam_policy" "CodeBuildVpcPolicy-eks-cicd-build-app" {
  description = "Policy used in trust relationship with CodeBuild"
  name        = format("%s-CodeBuildVpcPolicy-eks-cicd-build-app",data.aws_ssm_parameter.tf-eks-id.value)
  path        = "/service-role/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeDhcpOptions",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeVpcs",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "ec2:CreateNetworkInterfacePermission",
          ]
          Condition = {
            StringEquals = {
              "ec2:AuthorizedService" = "codebuild.amazonaws.com"
              "ec2:Subnet" = [
                format("arn:aws:ec2:%s:%s:subnet/subnet-00cc72ac5b0b79dd4",data.aws_region.current.name,data.aws_caller_identity.current.account_id),

              ]
            }
          }
          Effect   = "Allow"
          Resource = format("arn:aws:ec2:%s:%s:network-interface/*", data.aws_region.current.name, data.aws_caller_identity.current.account_id),

        },
      ]
      Version = "2012-10-17"
    }
  )
}
