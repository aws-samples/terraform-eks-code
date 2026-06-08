# Kubernetes Provider Configuration
# Configures access to the EKS cluster for Terraform operations
# Uses AWS CLI for authentication via IRSA

provider "kubernetes" {
  # Cluster API endpoint from SSM parameter
  host                   = data.aws_ssm_parameter.endpoint.value
  
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

# Helm Provider Configuration
# Used to install Helm charts for observability components
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

# Amazon Managed Prometheus Workspace - commented out
# The eks_monitoring module creates this automatically
#resource "aws_prometheus_workspace" "amp-demo" {
#  alias = "amp-demo"
#  tags = {
#    Environment = "amp-tfeks-workshop"
#  }
#}

# Grafana Workspace Data Source - commented out
# Used if referencing an existing workspace
#data "aws_grafana_workspace" "this" {
#  workspace_id = aws_grafana_workspace.workshop.id
#}

# AWS Observability Accelerator - EKS Monitoring Module
# Deploys a complete observability stack for EKS
# Uses v2.13.1 (latest stable release)
# Includes Prometheus, Grafana, ADOT, dashboards, and alerts

module "eks_monitoring" {
  # Source: AWS Observability Accelerator GitHub repository
  # Pinned to v2.13.1 (latest stable release compatible with AWS provider 5.x)
  source = "github.com/aws-observability/terraform-aws-observability-accelerator//modules/eks-monitoring?ref=v2.13.1"

  # EKS cluster identifier
  eks_cluster_id = data.aws_ssm_parameter.cluster-name.value

  # AWS Distro for OpenTelemetry (ADOT) Operator
  # Disabled: The ADOT v1beta1 webhook rejects the v2.13.1 string-format config.
  # The CloudWatch Observability add-on (installed in addons stage) provides
  # equivalent metrics/logs collection without this conflict.
  enable_amazon_eks_adot = false

  # Cert Manager
  # Manages TLS certificates for ADOT operator webhooks
  enable_cert_manager = true

  # API Server Monitoring
  # Enables monitoring of Kubernetes API server metrics
  enable_apiserver_monitoring = true

  # External Secrets Operator
  # Syncs Grafana API key from AWS Secrets Manager to Kubernetes
  enable_external_secrets = true

  # Grafana Configuration
  grafana_api_key         = aws_grafana_workspace_api_key.key.key
  target_secret_name      = "grafana-admin-credentials"
  target_secret_namespace = "grafana-operator"
  grafana_url             = format("https://%s", aws_grafana_workspace.workshop.endpoint)

  # Dashboards
  enable_dashboards = true

  # Amazon Managed Prometheus (AMP)
  enable_managed_prometheus = true

  # Alert Manager
  enable_alertmanager = true

  # Prometheus Configuration
  prometheus_config = {
    global_scrape_interval = "60s"
    global_scrape_timeout  = "15s"
  }

  # Logging and Tracing
  enable_logs    = true
  enable_tracing = true
}


