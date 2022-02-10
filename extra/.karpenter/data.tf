# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

data "aws_eks_cluster" "eks" {
  name = var.cluster-name
}

