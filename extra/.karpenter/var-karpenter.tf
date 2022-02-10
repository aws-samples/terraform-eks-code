# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "karpenter_namespace" {
  description = "The K8S namespace to deploy Karpenter into"
  default     = "karpenter"
  type        = string
}

variable "karpenter_version" {
  description = "Karpenter Version"
  default     = "0.6.0"
  type        = string
}

variable "karpenter_target_nodegroup" {
  description = "The node group to deploy Karpenter to"
  type        = string
  default="ng1"
}

variable "bottlerocket_k8s_version" {
  description = "Kubernetes version for Bottlerocket AMI"
  default     = "1.21"
  type        = string
}

variable "karpenter_ec2_instance_types" {
  description = "List of instance types that can be used by Karpenter"
  type        = list(string)
  default = [
  "t3.large",
  "t3.medium",
  "m5.large",
  "m5a.large",
  "m5.xlarge",
  "m5a.xlarge",
  "m5.2xlarge",
  "m5a.2xlarge",
  "m6g.large",
  "m6g.xlarge",
  "m6g.2xlarge",
]
}


variable "karpenter_ec2_arch" {
  description = "List of CPU architecture for the EC2 instances provisioned by Karpenter"
  type        = list(string)
  default     = ["amd64"]
}


variable "karpenter_ec2_capacity_type" {
  description = "EC2 provisioning capacity type"
  type        = list(string)
  default     = ["spot", "on-demand"]
}

variable "karpenter_ttl_seconds_after_empty" {
  description = "Node lifetime after empty"
  type        = number
  default = 300
}

variable "karpenter_ttl_seconds_until_expired" {
  description = "Node maximum lifetime"
  type        = number
  default = 604800
}