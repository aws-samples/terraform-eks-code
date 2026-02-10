# Input Variables for tf-setup Stage
# These can be overridden via TF_VAR_ environment variables or .tfvars files

# AWS Region for deployment
# TF_VAR_region can override this
variable "region" {
  description = "The name of the AWS Region"
  type        = string
  default     = "eu-west-1"
}

# AWS CLI profile to use (currently not used in provider config)
variable "profile" {
  description = "The name of the AWS profile in the credentials file"
  type        = string
  default     = "default"
}

# EKS cluster name - used throughout all stages
variable "cluster-name" {
  description = "The name of the EKS Cluster"
  type        = string
  default     = "eks-workshop"
}

# Kubernetes version for EKS cluster
variable "eks_version" {
  type    = string
  default = "1.33"
}

# Unused variable - kept for compatibility
# TODO: Remove if not needed
variable "no-output" {
  description = "The name of the EKS Cluster"
  type        = string
  default     = "secret"
  sensitive   = true
}



