data "aws_security_group" "primary_eks_sec_grp" {
  id = module.eks.cluster_primary_security_group_id
}