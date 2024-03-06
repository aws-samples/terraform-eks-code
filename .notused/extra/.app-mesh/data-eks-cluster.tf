data "aws_eks_cluster" "eks_cluster" {
  name = data.terraform_remote_state.cluster.outputs.cluster-name
}

