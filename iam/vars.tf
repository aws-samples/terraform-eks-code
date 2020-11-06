variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
  default     = "at-terraform-eks-workshop1"
}

variable "table_name" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "at-terraform-eks-workshop1-iam"
}

# TF_VAR_region
variable "region" {
  description = "The name of the AWS Region"
  type        = string
  default     = "eu-west-1"
  #default     = "eu-west-1"
}

variable "profile" {
  description = "The name of the AWS profile in the credentials file"
  type        = string
  default     = "default"
}
