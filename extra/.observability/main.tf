module "eks_observability_accelerator" {
  source = "github.com/aws-observability/terraform-aws-observability-accelerator?ref=v1.5.0"
  aws_region = data.aws_region.current.name
  eks_cluster_id = data.aws_ssm_parameter.tf-eks-cluster-name.value
  enable_managed_prometheus = true
  enable_managed_grafana       = false
  managed_grafana_workspace_id = var.grafana_id
  grafana_api_key              = var.grafana_api_key
}

module "workloads_infra" {
  source = "github.com/aws-observability/terraform-aws-observability-accelerator/workloads/infra?ref=v1.5.0a"

  eks_cluster_id = data.aws_ssm_parameter.tf-eks-cluster-name.value

  dashboards_folder_id            = module.eks_observability_accelerator.grafana_dashboards_folder_id
  managed_prometheus_workspace_id = module.eks_observability_accelerator.managed_prometheus_workspace_id

  managed_prometheus_workspace_endpoint = module.eks_observability_accelerator.managed_prometheus_workspace_endpoint
  managed_prometheus_workspace_region   = module.eks_observability_accelerator.managed_prometheus_workspace_region
}