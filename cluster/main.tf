
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

data "aws_availability_zones" "available" {}
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

locals {
  #name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  name            = data.aws_ssm_parameter.tf-eks-cluster-name.value
  cluster_version = data.aws_ssm_parameter.tf-eks-version.value
  region          = data.aws_ssm_parameter.tf-eks-region.value


  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  #source = "../.."
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"
  
  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni    = {
        most_recent              = true
        before_compute           = true
    }
    aws-ebs-csi-driver   = {
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }

    coredns = {
      most_recent = true
    }
  }


  vpc_id                   = data.aws_ssm_parameter.eks-vpc.value
  subnet_ids               = jsondecode(data.aws_ssm_parameter.private_subnets.value)
  control_plane_subnet_ids = jsondecode(data.aws_ssm_parameter.intra_subnets.value)

  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    # We need to add in the Karpenter node IAM role for nodes launched by Karpenter
    {
      rolearn  = module.karpenter.role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
  ]

  eks_managed_node_groups = {
    mg_5 = {
      node_group_name = "managed-ondemand"
      instance_types  = ["t3a.large"]
      min_size        = 1
      max_size        = 3
      desired_size    = 2
      #subnet_ids      = module.vpc.private_subnets
      subnet_ids      =  jsondecode(data.aws_ssm_parameter.private_subnets.value)
    }


  }
  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.name
  })

}

################################################################################
# Karpenter
################################################################################

module "karpenter" {

  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "19.16.0"

  cluster_name           = module.eks.cluster_name
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn


  iam_role_additional_policies = [ 
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
     "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  

  policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEKSWorkerNodePolicy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  tags = local.tags
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  #version             = "v0.21.1"
  version             = "v0.31.2"

  set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.irsa_arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = module.karpenter.instance_profile_name
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.karpenter.queue_name
  }
}


module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  # create_role      = false
  role_name_prefix = "${module.eks.cluster_name}-ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}


