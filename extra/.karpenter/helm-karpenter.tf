# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

resource "helm_release" "karpenter" {
  depends_on = [
    aws_ec2_tag.karpenter_tags,null_resource.modify_aws_auth
  ]

  namespace        = var.karpenter_namespace
  create_namespace = true

  name       = "karpenter"
  #repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = var.karpenter_version

  set {
    name  = "controller.image"
    value = format("%s.dkr.ecr.%s.amazonaws.com/karpenter/controller:v%s",data.aws_caller_identity.current.account_id,data.aws_region.current.name,var.karpenter_version)
  }

  set {
    name  = "webhook.image"
    value = format("%s.dkr.ecr.%s.amazonaws.com/karpenter/webhook:v%s",data.aws_caller_identity.current.account_id,data.aws_region.current.name,var.karpenter_version)
  }


  values = [
    templatefile(
      "${path.module}/templates/values.yaml.tpl",
      {
        "karpenter_iam_role"   = module.iam_assumable_role_karpenter.iam_role_arn,
        "cluster_name"         = var.cluster-name,
        "cluster_endpoint"     = data.aws_eks_cluster.eks.endpoint,
        "karpenter_node_group" = data.terraform_remote_state.nodeg.outputs.ng1-name
      }
    )
  ]
}

# A default Karpenter Provisioner manifest is created as a sample.
# Provisioner Custom Resource cannot be created at the same time as the CRD, so manifest file is created instead
# https://github.com/hashicorp/terraform-provider-kubernetes/issues/1367
resource "local_file" "karpenter_provisioner" {
  content = yamlencode({
    "apiVersion" = "karpenter.sh/v1alpha5"
    "kind"       = "Provisioner"
    "metadata" = {
      "name" = "default"
    }
    "spec" = {
      "labels" = {
        "purpose" = "demo"
      }
      "provider" = {
        # The launch template already has instance profile, so instanceProfile field is not required
        # As of today the Provisioner CRD requires it regardless. Fix is coming in future releases
        "instanceProfile" = aws_iam_instance_profile.karpenter_node.name
        "launchTemplate"  = aws_launch_template.bottlerocket.name
        "securityGroupSelector" = {
          "Name"  = "${data.aws_eks_cluster.eks.vpc_config.0.cluster_security_group_id}"
        }        
        "subnetSelector" = {
          #"Name" = "*${var.cluster-name}*"
          "Name" = "Private*"
        }
      }
      "requirements" = [
        {
          "key"      = "node.kubernetes.io/instance-type"
          "operator" = "In"
          "values"   = "${var.karpenter_ec2_instance_types}"
        },
        {
          "key"      = "topology.kubernetes.io/zone"
          "operator" = "In"
          "values"   = data.aws_availability_zones.az.names
        },
        {
          "key"      = "kubernetes.io/arch"
          "operator" = "In"
          "values"   = "${var.karpenter_ec2_arch}"
        },
        {
          "key"      = "karpenter.sh/capacity-type"
          "operator" = "In"
          "values"   = "${var.karpenter_ec2_capacity_type}"
        },
      ]
      "ttlSecondsAfterEmpty"   = "${var.karpenter_ttl_seconds_after_empty}"
      "ttlSecondsUntilExpired" = "${var.karpenter_ttl_seconds_until_expired}" # 7 days
    }
  })

  filename = "${path.module}/default-provisioner.yaml"
}