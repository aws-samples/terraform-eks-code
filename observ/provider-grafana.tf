# Grafana Provider Configuration
# Required by the AWS Observability Accelerator v3.0 eks-monitoring module
# Used for provisioning dashboards in Amazon Managed Grafana

terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 2.9"
    }
  }
}
