module "eks" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.0"

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = format("arn:aws:iam::%s:role/eksworkshop-admin",data.aws_caller_identity.current.account_id)
      username = "role1"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::66666666666:user/user1"
      userarn  = format("arn:aws:iam::%s:user/user1",data.aws_caller_identity.current.account_id)
      username = "user1"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_accounts = [
    data.aws_caller_identity.current.account_id
  ]
}