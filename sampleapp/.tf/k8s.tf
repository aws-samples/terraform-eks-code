terraform {
  required_version = ">= 1.9.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.36.0"
    }
  }
}
provider "kubernetes" {
  config_path = "~/.kube/config"
}
