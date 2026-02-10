# Kubernetes Provider Configuration
# Uses local kubeconfig for authentication
# Assumes kubectl is already configured (via cluster stage)

provider "kubernetes" {
  config_path = "~/.kube/config"
}
