data "aws_ssm_parameter" "eks-ami" {
  name=format("/aws/service/eks/optimized-ami/%s/amazon-linux-2/recommended/image_id", data.aws_eks_cluster.eks_cluster.version)
}