# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

data "aws_ssm_parameter" "bottlerocket_ami" {
  name = "/aws/service/bottlerocket/aws-k8s-${var.bottlerocket_k8s_version}/x86_64/latest/image_id"
}

# Need to create custom Launch Template to use Bottlerocket - https://github.com/aws/karpenter/issues/923
resource "aws_launch_template" "bottlerocket" {
  name = "${var.cluster-name}-karpenter-bottlerocket"

  image_id = data.aws_ssm_parameter.bottlerocket_ami.value

  iam_instance_profile {
    name = aws_iam_instance_profile.karpenter_node.name
  }

  vpc_security_group_ids = [
    data.aws_eks_cluster.eks.vpc_config.0.cluster_security_group_id
  ]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(templatefile(
    "${path.module}/templates/bottlerocket-userdata.toml.tpl",
    {
      "cluster_endpoint"       = data.aws_eks_cluster.eks.endpoint,
      "cluster_ca_certificate" = data.aws_eks_cluster.eks.certificate_authority[0].data
      "cluster_name"           = var.cluster-name,
    }
  ))
}