provider "kubernetes" {
  host                   = data.aws_ssm_parameter.endpoint.value
  cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
  config_path = "~/.kube/config"
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_ssm_parameter.endpoint.value
    cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
    }
  }
}


## base

data "aws_grafana_workspace" "this" {
  workspace_id = data.aws_ssm_parameter.tf-eks-grafana-id.value
}


# eks 

module "eks_monitoring" {

  #source = "github.com/aws-observability/terraform-aws-observability-accelerator//modules/eks-monitoring"
  source = "github.com/aws-observability/terraform-aws-observability-accelerator//modules/eks-monitoring?ref=v2.0.0"

  eks_cluster_id = data.aws_ssm_parameter.cluster-name.value


  #enable_fluxcd=false

  # deploys AWS Distro for OpenTelemetry operator into the cluster ! required
  enable_amazon_eks_adot = true

  # reusing existing certificate manager? set to false  defaults to true
  enable_cert_manager = true

  # enable EKS API server monitoring
  enable_apiserver_monitoring = true

  # deploys external-secrets in to the cluster
  enable_external_secrets = true
  grafana_api_key         = aws_grafana_workspace_api_key.key.key
  target_secret_name      = "grafana-admin-credentials"
  target_secret_namespace = "grafana-operator"
  grafana_url             = module.aws_observability_accelerator.managed_grafana_workspace_endpoint

  # control the publishing of dashboards by specifying the boolean value for the variable 'enable_dashboards', default is 'true'
  #enable_dashboards = var.enable_dashboards
  #dashboards_folder_id            = module.aws_observability_accelerator.grafana_dashboards_folder_id
  managed_prometheus_workspace_id = module.aws_observability_accelerator.managed_prometheus_workspace_id

  managed_prometheus_workspace_endpoint = module.aws_observability_accelerator.managed_prometheus_workspace_endpoint
  managed_prometheus_workspace_region   = module.aws_observability_accelerator.managed_prometheus_workspace_region

  # optional, defaults to 60s interval and 15s timeout
  prometheus_config = {
    global_scrape_interval = "60s"
    global_scrape_timeout  = "15s"
  }

  enable_logs = true # logs for the observability accelerator itself (I think)
  enable_tracing = true

  #tags = local.tags

  depends_on = [
    module.aws_observability_accelerator
  ]
}


