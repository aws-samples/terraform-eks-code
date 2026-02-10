# Local Variables for Network Configuration
# These values are used throughout the net stage

locals {
  # Cluster name from SSM parameter (created by tf-setup stage)
  # nonsensitive() allows use in resource names despite being from SSM
  name            = nonsensitive(data.aws_ssm_parameter.tf-eks-cluster-name.value)
  
  # Kubernetes version from SSM parameter
  cluster_version = data.aws_ssm_parameter.tf-eks-version.value
  
  # AWS region from variable
  region          = var.region

  # Primary VPC CIDR block
  # Used for public and intra subnets
  vpc_cidr = "10.141.0.0/16"
  
  # Secondary CIDR block for private subnets (worker nodes)
  # 100.64.0.0/10 is RFC 6598 shared address space
  # Provides large IP space for pod networking
  secondary_cidr_blocks = ["100.65.0.0/16"]
  
  # Use first 3 availability zones in the region
  # Provides high availability across multiple AZs
  azs      = slice(data.aws_availability_zones.az.names, 0, 3)

  # Standard tags applied to all resources
  # Compatible with eksworkshop.com tagging conventions
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.cluster-name
    workshop    = "tf-eks"
  }

}