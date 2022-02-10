# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

resource "aws_ec2_tag" "karpenter_tags" {
  for_each    = data.aws_eks_cluster.eks.vpc_config.0.subnet_ids
  resource_id = each.value
  key         = format("kubernetes.io/cluster/%s", var.cluster-name)
  value       = "true"
}