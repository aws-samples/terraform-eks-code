
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

#resource "aws_ec2_instance_metadata_defaults" "metadata" {
#  http_endpoint               = "enabled"
#  http_tokens                 = "required"
#  http_put_response_hop_limit = 1
#  instance_metadata_tags      = "disabled"
#}



data "aws_availability_zones" "available" {}
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

locals {
  #name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  name            = nonsensitive(data.aws_ssm_parameter.tf-eks-cluster-name.value)
  cluster_version = data.aws_ssm_parameter.tf-eks-version.value
  region          = data.aws_ssm_parameter.tf-eks-region.value


  #vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    created-by = "eks-workshop-v2"
    env        = nonsensitive(data.aws_ssm_parameter.tf-eks-cluster-name.value)
  }
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  #source = "../.."
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"
  
  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = false
  cluster_endpoint_private_access = true
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  enable_irsa = true

  enable_cluster_creator_admin_permissions = true
  authentication_mode = "API_AND_CONFIG_MAP" # this mode is default

  cluster_ip_family = "ipv6"
  create_cni_ipv6_iam_policy = true
  ## need to use this ^^  with karpenter nodes

  cluster_compute_config = {
    enabled    = true
    #node_pools = ["general-purpose","system"]
    node_pools = []
  }

# External encryption key

  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = module.kms.key_arn
  }

  vpc_id                   = data.aws_ssm_parameter.eks-vpc.value
  subnet_ids               = jsondecode(data.aws_ssm_parameter.private_subnets.value)
  #control_plane_subnet_ids = jsondecode(data.aws_ssm_parameter.intra_subnets.value)


  cluster_security_group_additional_rules = {
    # Test: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2319
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      cidr_blocks = [data.aws_vpc.vpc-default.cidr_block]
    }
  }
}

module "disabled_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  create = false
}


module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"

  aliases               = ["eks/${local.name}"]
  description           = "${local.name} cluster encryption key"
  enable_default_policy = true
  key_owners            = [data.aws_caller_identity.current.arn]

  tags = local.tags
}


