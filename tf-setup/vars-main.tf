# TF_VAR_region
variable "region" {
  description = "The name of the AWS Region"
  type        = string
  default     = "eu-west-1"
}

variable "profile" {
  description = "The name of the AWS profile in the credentials file"
  type        = string
  default     = "default"
}

variable "cluster-name" {
  description = "The name of the EKS Cluster"
  type        = string
  default     = "mycluster1"
}

variable "stages" {
type=list(string)
default=["net","iam","c9net","cluster","nodeg","cicd","eks-cidr","sampleapp"]
}

variable "stagecount" {
type=number
default=8
}

