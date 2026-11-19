# Kubernetes Provider Configuration
# Configures access to the EKS cluster for Terraform operations
# Uses AWS CLI for authentication via IRSA
provider "kubernetes" {
  # Cluster API endpoint from SSM parameter
  host = data.aws_ssm_parameter.endpoint.value
  # Cluster CA certificate (base64 decoded)
  cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
  # Local kubeconfig file (fallback)
  config_path = "~/.kube/config"
  # AWS CLI exec authentication
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
  }
}

# Helm Provider Configuration (helm provider 3 syntax)
# Used to install the OpenTelemetry Collector, kube-state-metrics and node-exporter
provider "helm" {
  kubernetes = {
    host                   = data.aws_ssm_parameter.endpoint.value
    cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
    }
  }
}

# Grafana Provider Configuration
# v3 provisions dashboards directly in Amazon Managed Grafana via the Grafana API
# Note: the API key (grafana-key.tf) expires after seconds_to_live; plans fail once it has expired
provider "grafana" {
  url  = format("https://%s", aws_grafana_workspace.workshop.endpoint)
  auth = aws_grafana_workspace_api_key.key.key
}

# AWS Observability Accelerator - EKS Monitoring Module (v3)
# v3 is profile-driven and not yet tagged upstream, so it is pinned to a commit on main
# (4c39cde, 2026-04-24) rather than tracking the branch
# self-managed-amp: OpenTelemetry Collector -> Amazon Managed Prometheus (metrics) and X-Ray (traces),
# plus kube-state-metrics and node-exporter. No ADOT operator, Flux, Grafana Operator or External Secrets.
module "eks_monitoring" {
  source = "github.com/aws-observability/terraform-aws-observability-accelerator//modules/eks-monitoring?ref=4c39cde"

  providers = {
    grafana = grafana
  }

  collector_profile = "self-managed-amp"

  # EKS cluster identifier
  eks_cluster_id = data.aws_ssm_parameter.cluster-name.value

  # Prometheus scrape settings
  prometheus_config = {
    global_scrape_interval = "60s"
    global_scrape_timeout  = "15s"
  }

  # Pinned below the module default (0.114.0): the module sets exporters.logging = null, which
  # stays in the rendered config, and collectors >= 0.111 reject the removed logging exporter.
  # Chart 0.107.0 = collector 0.110.0. Remove once fixed upstream.
  otel_collector_chart_version = "0.107.0"
  # With enable_logs = false the module adds no logs pipeline, so the chart's default one is kept.
  # It references memory_limiter and debug, which the module removes, and the collector refuses to start.
  # Setting it to null removes the chart default.
  helm_values = {
    "config.service.pipelines.logs" = "null"
  }

  # Traces to X-Ray via the OTel Collector
  enable_tracing = true
  # Logs off: the CloudWatch Observability add-on (addons stage) already ships container logs
  enable_logs = false

  # Dashboards provisioned into Grafana by Terraform
  enable_dashboards = true
  grafana_endpoint  = format("https://%s", aws_grafana_workspace.workshop.endpoint)
  grafana_api_key   = aws_grafana_workspace_api_key.key.key
}

# Grafana data source for Amazon Managed Prometheus
# The AMP profiles only output the data source settings; the dashboards select a Prometheus data source
resource "grafana_data_source" "amp" {
  type       = module.eks_monitoring.amp_datasource_config.type
  name       = "Amazon Managed Prometheus"
  url        = module.eks_monitoring.amp_datasource_config.endpoint
  is_default = true

  json_data_encoded = jsonencode({
    httpMethod    = module.eks_monitoring.amp_datasource_config.http_method
    sigV4Auth     = true
    sigV4AuthType = "ec2_iam_role" # Amazon Managed Grafana workspace IAM role
    sigV4Region   = module.eks_monitoring.amp_datasource_config.sigv4_region
  })
}
