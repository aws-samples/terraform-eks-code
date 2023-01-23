


resource "aws_eks_addon" "kube-proxy" {
  #depends_on     = [aws_eks_node_group.ng1]
  cluster_name = data.aws_ssm_parameter.tf-eks-cluster-name.value
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "coredns" {
  #depends_on     = [aws_eks_node_group.ng1]
  cluster_name = data.aws_ssm_parameter.tf-eks-cluster-name.value
  addon_name   = "coredns"
}