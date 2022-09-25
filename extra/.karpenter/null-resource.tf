# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# null_resource is generally not preferrable but it is simple to implement.
# For production use, use other methods e.g. https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/complete/main.tf
# Need eksctl to function properly
resource "null_resource" "modify_aws_auth" {
  triggers = {
    iam_role_arn = aws_iam_role.karpenter_node.arn
    cluster      = var.cluster-name
  }

  depends_on = [
    aws_iam_role.karpenter_node
  ]

  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
            eksctl create iamidentitymapping \
                --username system:node:{{EC2PrivateDNSName}} \
                --cluster ${self.triggers.cluster} \
                --arn ${self.triggers.iam_role_arn} \
                --group system:bootstrappers \
                --group system:nodes
            # get the chart
            rm -rf karpenter
            rm -rf karpenter-*.tgz
            helm repo add karpenter https://charts.karpenter.sh
            helm repo update
            helm fetch karpenter/karpenter --version ${var.karpenter_version}
            tar -xzf karp*.tgz   
            aws iam create-service-linked-role --aws-service-name spot.amazonaws.com 2> /dev/null  
        EOT
  }

  provisioner "local-exec" {
    on_failure  = fail
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
            eksctl delete iamidentitymapping \
                --cluster ${self.triggers.cluster} \
                --arn ${self.triggers.iam_role_arn}
        EOT
  }
}

  