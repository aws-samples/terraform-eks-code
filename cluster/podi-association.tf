resource "aws_eks_access_entry" "automode_node" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.eks.node_iam_role_arn
  type          = "EC2"
}

resource "aws_eks_access_policy_association" "automode_node" {
  cluster_name = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy"
  principal_arn = module.eks.node_iam_role_arn
    access_scope {
    type = "cluster"
  }
}