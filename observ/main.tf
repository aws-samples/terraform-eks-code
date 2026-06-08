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
# Uses the v3.0 profile-driven architecture
# Profile: self-managed-amp (deploys OTel Collector via Helm)
# Supports metrics, traces (X-Ray), and logs (CloudWatch)

# Required: Grafana provider for dashboard provisioning
provider "grafana" {
  url  = format("https://%s", aws_grafana_workspace.workshop.endpoint)
  auth = aws_grafana_workspace_api_key.key.key
}

module "eks_monitoring" {
  # Source: AWS Observability Accelerator GitHub repository
  # Using main branch which has the v3.0 profile-driven architecture
  source = "github.com/aws-observability/terraform-aws-observability-accelerator//modules/eks-monitoring"

  # Pass the grafana provider to the module
  providers = {
    grafana = grafana
  }

  # Required: Collector profile
  # Options: "cloudwatch-otlp", "managed-metrics", "self-managed-amp"
  # self-managed-amp: Deploys OTel Collector via Helm, supports metrics, traces, and logs
  collector_profile = "self-managed-amp"

  # EKS cluster identifier
  eks_cluster_id = data.aws_ssm_parameter.cluster-name.value

  # Grafana Configuration
  # API key for dashboard provisioning
  grafana_api_key = aws_grafana_workspace_api_key.key.key

  # Tracing
  # Enables distributed tracing with AWS X-Ray
  # Provides service maps and performance insights
  enable_tracing = true

  # Logging
  # Enables log collection via OTel Collector to CloudWatch Logs
  enable_logs = true
}


