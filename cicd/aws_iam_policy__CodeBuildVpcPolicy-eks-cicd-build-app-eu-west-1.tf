
# aws_iam_policy.CodeBuildVpcPolicy-eks-cicd-build-app:
resource "aws_iam_policy" "CodeBuildVpcPolicy-eks-cicd-build-app" {
  description = "Policy used in trust relationship with CodeBuild"
  name        = "CodeBuildVpcPolicy-eks-cicd-build-app"
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
                format("arn:aws:ec2:%s:%s:subnet/subnet-00cc72ac5b0b79dd4",data.aws_caller_identity.current.account_id, data.aws_region.current.name),
                #"arn:aws:ec2:eu-west-1:566972129213:subnet/subnet-00cc72ac5b0b79dd4",
              ]
            }
          }
          Effect   = "Allow"
          Resource = format("arn:aws:ec2:%s:%s:network-interface/*",data.aws_caller_identity.current.account_id, data.aws_region.current.name),
          #Resource = "arn:aws:ec2:eu-west-1:566972129213:network-interface/*"
        },
      ]
      Version = "2012-10-17"
    }
  )
}
