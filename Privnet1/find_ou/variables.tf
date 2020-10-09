variable "parent_id" {
  description = "The unique identifier (ID) of the root or OU whose child OUs you want to search."
  type        = string
}

variable "ou_name" {
  description = "The name of the OU you want to find."
  type        = string
}

variable "profile" {
  description = "AWS Profile the CLI should use"
  type        = string
  default     = "master-account"
}
