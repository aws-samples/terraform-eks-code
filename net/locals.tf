locals {
  #name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  name            = nonsensitive(data.aws_ssm_parameter.tf-eks-cluster-name.value)
  cluster_version = data.aws_ssm_parameter.tf-eks-version.value
  region          = var.region


  vpc_cidr = "10.141.0.0/16"
  secondary_cidr_blocks = ["100.65.0.0/16"]
  azs      = slice(data.aws_availability_zones.az.names, 0, 3)

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}