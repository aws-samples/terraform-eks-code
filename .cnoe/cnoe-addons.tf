data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "template_file" "crossplane_boundary_policy" {
  template = file("$crossplane-permissions-boundry.json")
  vars = {
    AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
  }
}

data "template_file" "external_secret_policy" {
  template = file("external-secrets.json")
  vars = {
    AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
  }
}


resource "aws_iam_policy" "crossplane_boundary" {
  name   = "crossplane-permissions-boundary"
  policy = data.template_file.crossplane_boundary_policy.rendered

  tags = local.tags
}

module "crossplane_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "crossplane-provider-aws"

  additional_policy_arns   = {
    admin = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
  permissions_boundary_arn = aws_iam_policy.crossplane_boundary.arn

  associations = {
    crossplane = {
      cluster_name    = module.eks.cluster_name
      namespace       = "crossplane-system"
      service_account = "provider-aws"
    }
  }

  tags = local.tags
}

