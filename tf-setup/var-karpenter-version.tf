variable "karpenter_version" {
  description = "Karpenter Version"
  default     = "0.16.2"
  type        = string
}


variable "bottlerocket_k8s_version" {
  description = "Kubernetes version for Bottlerocket AMI"
  default     = "1.21"
  type        = string
}

