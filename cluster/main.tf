
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
  name            = nonsensitive(data.aws_ssm_parameter.tf-eks-cluster-name.value)
  cluster_version = data.aws_ssm_parameter.tf-eks-version.value
  region          = data.aws_ssm_parameter.tf-eks-region.value


  vpc_cidr = "10.0.0.0/16"
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
  #version = "19.21.0"
  
  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = false
  cluster_endpoint_private_access = true
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  enable_cluster_creator_admin_permissions = true
  authentication_mode = "API_AND_CONFIG_MAP" # this mode is default

  cluster_ip_family = ipv6

# When enabling authentication_mode = "API_AND_CONFIG_MAP" , 
# EKS will automatically create an access entry for the IAM role(s) used by 
# managed nodegroup(s) and Fargate profile(s).
# There are no additional actions required by users. 
# For self-managed nodegroups and the Karpenter sub-module, 
# this project automatically adds the access entry on behalf of users 
# so there are no additional actions required by users.


# optional additions
#access_entries = {
#    # One access entry with a policy associated
#    example = {
#      kubernetes_groups = []
#      principal_arn     = "arn:aws:iam::123456789012:role/something"

#      policy_associations = {
#        example = {
#          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
#          access_scope = {
#            namespaces = ["default"]
#            type       = "namespace"
#          }
#        }
#      }
#    }
#}


# External encryption key

  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = module.kms.key_arn
  }

  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni    = {
        most_recent              = true
        before_compute           = true
        configuration_values = jsonencode({
          env = {
            ENABLE_POD_ENI                    = "true"
            ENABLE_PREFIX_DELEGATION          = "true"
            POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
          }
          enableNetworkPolicy = "true"
      })

    }

    eks-pod-identity-agent = {}
    coredns = {
      most_recent = true
    }

    aws-ebs-csi-driver   = {
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }

    amazon-cloudwatch-observability = {
        most_recent = true
      }

  }

  vpc_id                   = data.aws_ssm_parameter.eks-vpc.value
  subnet_ids               = jsondecode(data.aws_ssm_parameter.private_subnets.value)
  control_plane_subnet_ids = jsondecode(data.aws_ssm_parameter.intra_subnets.value)

  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false

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


  eks_managed_node_groups = {
    default = {
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "optional"
        instance_metadata_tags      = "disabled"
        http_put_response_hop_limit = "3"
      }
      node_group_name = "default"
      instance_types  = ["t3a.large"]
      min_size        = 3
      max_size        = 6
      desired_size    = 3
      labels = {
        workshop-default = "yes"
      }
      subnet_ids      =  jsondecode(data.aws_ssm_parameter.private_subnets.value)
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        AmazonEKSWorkerNodePolicy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        AmazonInspector2ManagedCispolicy = "arn:aws:iam::aws:policy/AmazonInspector2ManagedCisPolicy"
      }
      #  EKS K8s API cluster needs to be able to talk with the EKS worker nodes with port 15017/TCP and 15012/TCP which is used by Istio
      #  Istio in order to create sidecar needs to be able to communicate with webhook and for that network passage to EKS is needed.
      node_security_group_additional_rules = {
        ingress_15017 = {
          description                   = "Cluster API - Istio Webhook namespace.sidecar-injector.istio.io"
          protocol                      = "TCP"
          from_port                     = 15017
          to_port                       = 15017
          type                          = "ingress"
          source_cluster_security_group = true
        }
        ingress_15012 = {
          description                   = "Cluster API to nodes ports/protocols"
          protocol                      = "TCP"
          from_port                     = 15012
          to_port                       = 15012
          type                          = "ingress"
          source_cluster_security_group = true
        }
      }
    
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

################################################################################
# Karpenter
################################################################################

module "karpenter" {

  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  #version = "19.16.0"

  cluster_name           = module.eks.cluster_name
  enable_v1_permissions = true

  enable_pod_identity             = true
  create_pod_identity_association = true
  enable_irsa            = true
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEKSWorkerNodePolicy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  tags = local.tags
}

module "karpenter_disabled" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  create = false
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  # v0.33+ goes to beta apis - might break things !!
  #version             = "v0.31.2"
  #version             = "0.35.4"
  version = "1.0.6"
  wait = false

  values = [
    <<-EOT
    serviceAccount:
      name: ${module.karpenter.service_account}
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    EOT
  ]

  depends_on = [
    module.eks.eks_managed_node_group
    #module.eks.module.eks_managed_node_group.aws_eks_node_group
  ]
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


module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"

  aliases               = ["eks/${local.name}"]
  description           = "${local.name} cluster encryption key"
  enable_default_policy = true
  key_owners            = [data.aws_caller_identity.current.arn]

  tags = local.tags
}


