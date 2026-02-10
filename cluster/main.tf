# EKS Cluster Configuration
# Creates Amazon EKS cluster with Auto Mode, IRSA, and private endpoint
# This is the core Kubernetes control plane for the workshop

# AWS Provider for us-east-1 (Virginia)
# Required for ECR Public authentication token
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

# Instance metadata defaults - currently not used
# Uncomment to enforce IMDSv2 for enhanced security
#resource "aws_ec2_instance_metadata_defaults" "metadata" {
#  http_endpoint               = "enabled"
#  http_tokens                 = "required"  # Enforce IMDSv2
#  http_put_response_hop_limit = 1
#  instance_metadata_tags      = "disabled"
#}

# Data sources for AWS environment
data "aws_availability_zones" "available" {}

# ECR Public authorization token
# Required for pulling public container images
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

# Local variables for cluster configuration
# Values are read from SSM parameters created by tf-setup and net stages
locals {
  # Cluster name from SSM parameter
  name            = nonsensitive(data.aws_ssm_parameter.tf-eks-cluster-name.value)
  
  # Kubernetes version from SSM parameter
  cluster_version = data.aws_ssm_parameter.tf-eks-version.value
  
  # AWS region from SSM parameter
  region          = data.aws_ssm_parameter.tf-eks-region.value

  # Use first 3 availability zones for high availability
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  # Standard tags for all resources
  # Compatible with eksworkshop.com conventions
  tags = {
    created-by = "eks-workshop-v2"
    env        = nonsensitive(data.aws_ssm_parameter.tf-eks-cluster-name.value)
  }
}

################################################################################
# EKS Module
################################################################################

# Main EKS cluster configuration
# Uses the official AWS EKS Terraform module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.1"
  
  # Basic cluster configuration
  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  
  # Private cluster configuration
  # API endpoint only accessible from within VPC (via VPC peering)
  cluster_endpoint_public_access = false
  cluster_endpoint_private_access = true
  
  # Control plane logging
  # All log types enabled for comprehensive monitoring
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  # Enable IRSA (IAM Roles for Service Accounts)
  # Allows Kubernetes pods to assume IAM roles
  enable_irsa = true

  # Grant cluster creator admin permissions automatically
  enable_cluster_creator_admin_permissions = true
  
  # Authentication mode supports both EKS API and ConfigMap
  # Allows gradual migration to EKS API
  authentication_mode = "API_AND_CONFIG_MAP"

  # EKS Auto Mode configuration
  # Simplified node management with AWS-managed compute
  cluster_compute_config = {
    enabled    = true
    node_pools = []  # Node pools configured in nodepool stage
  }

  # External KMS key for secrets encryption
  # Using separate KMS module for better key management
  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]  # Encrypt Kubernetes secrets at rest
    provider_key_arn = module.kms.key_arn
  }

  # Network configuration from net stage
  vpc_id                   = data.aws_ssm_parameter.eks-vpc.value
  subnet_ids               = jsondecode(data.aws_ssm_parameter.private_subnets.value)  # Worker nodes
  control_plane_subnet_ids = jsondecode(data.aws_ssm_parameter.intra_subnets.value)   # Control plane ENIs

  # Additional security group rules
  # Allow kubectl access from default VPC (VSCode/Cloud9)
  cluster_security_group_additional_rules = {
    ingress_source_security_group_id = {
      description = "Ingress from another computed security group"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [data.aws_vpc.vpc-default.cidr_block]
    }
  }
}

# Disabled EKS module example
# Template for conditional cluster creation
# Not used in this workshop
module "disabled_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.1"

  create = false  # Do not create resources
}

# KMS key for cluster encryption
# Separate module for better key management and rotation
module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"

  # Key alias for easy identification
  aliases               = ["eks/${local.name}"]
  description           = "${local.name} cluster encryption key"
  
  # Enable default key policy (allows key owners full access)
  enable_default_policy = true
  
  # Current AWS account/user as key owner
  key_owners            = [data.aws_caller_identity.current.arn]

  tags = local.tags
}