# Kubernetes Provider Configuration
# Uses local kubeconfig for authentication
# Assumes kubectl is already configured (via cluster stage)

terraform {
  required_version = "> 1.12.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.5.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
