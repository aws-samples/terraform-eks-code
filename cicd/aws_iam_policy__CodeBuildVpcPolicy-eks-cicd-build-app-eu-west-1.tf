
# aws_iam_policy.CodeBuildVpcPolicy-eks-cicd-build-app-eu-west-1:
resource "aws_iam_policy" "CodeBuildVpcPolicy-eks-cicd-build-app-eu-west-1" {
  description = "Policy used in trust relationship with CodeBuild"
  name        = "CodeBuildVpcPolicy-eks-cicd-build-app-eu-west-1"
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
                "arn:aws:ec2:eu-west-1:566972129213:subnet/subnet-00cc72ac5b0b79dd4",
              ]
            }
          }
          Effect   = "Allow"
          Resource = "arn:aws:ec2:eu-west-1:566972129213:network-interface/*"
        },
      ]
      Version = "2012-10-17"
    }
  )
}
