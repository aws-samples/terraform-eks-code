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


