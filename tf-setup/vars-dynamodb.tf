variable "table_name_net" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_net"
}

variable "table_name_addons" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_addons"
}

variable "table_name_observ" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_observ"
}

variable "table_name_c9net" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_c9net"
}

variable "table_name_cluster" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_cluster"
}

variable "table_name_tf-setup" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "terraform_locks_tf-setup"
}

variable "stages" {
  type    = list(string)
  default = ["tf-setup", "net", "c9net", "cluster","addons", "observ"]
}

variable "stagecount" {
  type    = number
  default = 6
}
