module "eks_observability_accelerator" {
  source = "github.com/aws-observability/terraform-aws-observability-accelerator?ref=v1.5.0"
  aws_region = data.aws_region.current.name
  eks_cluster_id = "my-eks-cluster"
}