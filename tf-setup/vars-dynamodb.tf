variable "table_name_net" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "at-terraform-eks-workshop1-net"
}

variable "table_name_iam" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "at-terraform-eks-workshop1-iam"
}

variable "table_name_c9net" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "at-terraform-eks-workshop1-c9net"
}

variable "table_name_cicd" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "at-terraform-eks-workshop1-cicd"
}

variable "table_name_cluster" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "at-terraform-eks-workshop1-cluster"
}

variable "table_name_nodeg" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "at-terraform-eks-workshop1-nodeg"
}

variable "table_name_eks-cidr" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "at-terraform-eks-workshop1-eks-cidr"
}

variable "table_name_sampleapp" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "at-terraform-eks-workshop1-sampleapp"
}


