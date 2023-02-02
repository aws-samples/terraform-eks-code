
# CNI helm values here: https://github.com/aws/amazon-vpc-cni-k8s/blob/master/charts/aws-vpc-cni/values.yaml

locals {
  cni_config = file("${path.module}/cni.json")
}


resource "aws_eks_addon" "vpc-cni" {
  depends_on = [aws_eks_cluster.cluster]
  #depends_on     = [null_resource.gen_cluster_auth]
  cluster_name      = data.aws_ssm_parameter.tf-eks-cluster-name.value
  addon_name        = "vpc-cni"
  resolve_conflicts = "OVERWRITE"

  configuration_values = local.cni_config
  addon_version        = "v1.12.1-eksbuild.1"

  preserve = true

}

