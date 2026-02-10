# SSM Parameter Store - Cluster Configuration
# Stores EKS cluster outputs for use by downstream stages
# These parameters are read by nodepool, addons, and observ stages

# OIDC Provider ARN
# Used for creating IAM roles for service accounts (IRSA)
# Allows Kubernetes pods to assume IAM roles
resource "aws_ssm_parameter" "oidc_provider_arn" {
  name        = "/workshop/tf-eks/oidc_provider_arn"
  description = "The EKS cluster oidc arn"
  type        = "String"
  value       = module.eks.oidc_provider_arn
  tags = {
    workshop = "tf-eks-workshop"
  }
}

# Actual EKS cluster name
# May differ from the configured name in some cases
resource "aws_ssm_parameter" "cluster-name" {
  name        = "/workshop/tf-eks/eks-cluster-name"
  description = "The actual EKS cluster name"
  type        = "String"
  value       = module.eks.cluster_name
  tags = {
    workshop = "tf-eks-workshop"
  }
}

# Cluster primary security group ID
# Created by EKS for control-plane-to-data-plane communication
# Used for adding additional security group rules
resource "aws_ssm_parameter" "cluster-sg" {
  name        = "/workshop/tf-eks/cluster-sg"
  description = "The EKS cluster created sg"
  type        = "String"
  value       = module.eks.cluster_primary_security_group_id
  tags = {
    workshop = "tf-eks-workshop"
  }
}

# Cluster certificate authority data (base64 encoded)
# Required for kubectl and Helm provider configuration
# Usage: base64decode(data.aws_ssm_parameter.ca.value)
resource "aws_ssm_parameter" "ca" {
  name        = "/workshop/tf-eks/ca"
  description = "The EKS cluster cert authority"
  type        = "String"
  value       = module.eks.cluster_certificate_authority_data
  tags = {
    workshop = "tf-eks-workshop"
  }
}

# Cluster API endpoint URL
# Required for kubectl and Helm provider configuration
# Example: https://ABC123.gr7.us-east-1.eks.amazonaws.com
resource "aws_ssm_parameter" "endpoint" {
  name        = "/workshop/tf-eks/endpoint"
  description = "The EKS cluster endpoint"
  type        = "String"
  value       = module.eks.cluster_endpoint
  tags = {
    workshop = "tf-eks-workshop"
  }
}

# EKS node IAM role name
# Auto Mode node role for attaching additional policies
resource "aws_ssm_parameter" "eks-node-role-name" {
  name        = "/workshop/tf-eks/eks-node-role-name"
  description = "The EKS node role name"
  type        = "String"
  value       = module.eks.node_iam_role_name
  tags = {
    workshop = "tf-eks-workshop"
  }
}
