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
# Includes Prometheus, Grafana, ADOT, dashboards, and alerts

module "eks_monitoring" {
  # Source: AWS Observability Accelerator GitHub repository
  # Using latest version from main branch
  source = "github.com/aws-observability/terraform-aws-observability-accelerator//modules/eks-monitoring"
  #source = "github.com/aws-observability/terraform-aws-observability-accelerator//modules/eks-monitoring?ref=v2.13.0"

  # EKS cluster identifier
  eks_cluster_id = data.aws_ssm_parameter.cluster-name.value

  # FluxCD - commented out (not used in this deployment)
  #enable_fluxcd=false

  # AWS Distro for OpenTelemetry (ADOT) Operator
  # Deploys ADOT operator for collecting metrics, logs, and traces
  # Required for observability stack
  enable_amazon_eks_adot = true

  # Cert Manager
  # Manages TLS certificates for ADOT operator webhooks
  # Set to false if cert-manager is already installed
  enable_cert_manager = true

  # API Server Monitoring
  # Enables monitoring of Kubernetes API server metrics
  # Provides insights into control plane performance
  enable_apiserver_monitoring = true

  # External Secrets Operator
  # Syncs Grafana API key from AWS Secrets Manager to Kubernetes
  # Required for automated dashboard provisioning
  enable_external_secrets = true
  
  # Grafana Configuration
  # API key for dashboard provisioning
  grafana_api_key         = aws_grafana_workspace_api_key.key.key
  
  # Kubernetes secret configuration for Grafana credentials
  target_secret_name      = "grafana-admin-credentials"
  target_secret_namespace = "grafana-operator"
  
  # Grafana workspace URL
  grafana_url             = format("https://%s",aws_grafana_workspace.workshop.endpoint)

  # Dashboards
  # Automatically provisions pre-built dashboards in Grafana
  # Includes cluster, workload, and application dashboards
  enable_dashboards = true

  # Amazon Managed Prometheus (AMP)
  # Creates a new AMP workspace for metrics storage
  # Set to false if using an existing workspace
  enable_managed_prometheus       = true
  #managed_prometheus_workspace_id = var.managed_prometheus_workspace_id
  
  # Alert Manager
  # Sets up alert routing and notifications at the workspace level
  enable_alertmanager = true

  # Prometheus Configuration
  # Scrape interval: How often to collect metrics (60 seconds)
  # Scrape timeout: Maximum time for a scrape operation (15 seconds)
  prometheus_config = {
    global_scrape_interval = "60s"
    global_scrape_timeout  = "15s"
  }

  # Logging
  # Enables log collection for the observability accelerator components
  enable_logs = true

  # Tracing
  # Enables distributed tracing with AWS X-Ray
  # Provides service maps and performance insights
  enable_tracing = true

  # Tags - commented out
  # Apply custom tags to all resources
  #tags = local.tags
}


