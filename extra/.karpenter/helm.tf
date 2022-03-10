provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#provider "helm" {
#  kubernetes {
#    host                   = data.aws_eks_cluster.eks.endpoint
#    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#    exec {
#      api_version = "client.authentication.k8s.io/v1alpha1"
#      args        = ["eks", "get-token", "--cluster-name", var.cluster-name]
#      command     = "aws"
#    }
#  }
#}
