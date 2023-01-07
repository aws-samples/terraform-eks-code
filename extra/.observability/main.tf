module "eks_observability_accelerator" {
  source = "github.com/aws-observability/terraform-aws-observability-accelerator?ref=v1.5.0"
  aws_region = data.aws_region.current.name
  eks_cluster_id = data.aws_ssm_parameter.tf-eks-cluster-name.value
  enable_managed_prometheus = true
  enable_managed_grafana       = true
}