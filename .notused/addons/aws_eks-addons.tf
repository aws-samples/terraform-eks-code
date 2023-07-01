
# CNI helm values here: https://github.com/aws/amazon-vpc-cni-k8s/blob/master/charts/aws-vpc-cni/values.yaml

locals {
  cni_config = file("${path.module}/cni.json")
}

resource "aws_eks_addon" "vpc-cni" {
  #depends_on     = [aws_eks_node_group.ng1]
  cluster_name = data.aws_ssm_parameter.tf-eks-cluster-name.value
  addon_name   = "vpc-cni"
  resolve_conflicts = "PRESERVE"
  addon_version     = "v1.12.1-eksbuild.1"

  #configuration_values = local.cni_config

  preserve = true

}

