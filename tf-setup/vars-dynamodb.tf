variable "table_name_net" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_net"
}

variable "table_name_iam" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_iam"
}

variable "table_name_c9net" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_c9net"
}

variable "table_name_cicd" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_cicd"
}

variable "table_name_cluster" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_cluster"
}

variable "table_name_nodeg" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_nodeg"
}

variable "table_name_eks-cidr" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_eks-cidr"
}

variable "table_name_sampleapp" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_sampleapp"
}

variable "table_name_tf-setup" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_tf-setup"
}

variable "stages" {
  type    = list(string)
  default = ["tf-setup", "net", "iam", "c9net", "cluster", "nodeg", "cicd", "eks-cidr", "sampleapp"]
}

variable "stagecount" {
  type    = number
  default = 9
}
