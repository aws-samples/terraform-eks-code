# File generated by aws2tf see https://github.com/aws-samples/aws2tf
# aws_iam_role.eks-nodegroup-ng-ma-NodeInstanceRole:
resource "aws_iam_role" "eks-nodegroup-ng-ma-NodeInstanceRole" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = format("%s-eks-nodegroup-NodeInstanceRole",data.aws_ssm_parameter.tf-eks-id.value)
  path                  = "/"
  tags = {
    "Name" = format("%s-eks-nodegroup-ng-maneksami2/NodeInstanceRole",data.aws_ssm_parameter.tf-eks-id.value)
  }
}


