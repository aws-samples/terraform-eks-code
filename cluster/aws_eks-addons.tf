
# CNI helm values here: https://github.com/aws/amazon-vpc-cni-k8s/blob/master/charts/aws-vpc-cni/values.yaml

locals {
  cni_config = file("${path.module}/cni.json")
}


resource "aws_eks_addon" "vpc-cni" {
  depends_on     = [aws_eks_cluster.cluster]
  cluster_name = data.aws_ssm_parameter.tf-eks-cluster-name
  addon_name   = "vpc-cni"
  resolve_conflicts = "OVERWRITE"

  configuration_values = local.cni_config

  preserve = true

}

