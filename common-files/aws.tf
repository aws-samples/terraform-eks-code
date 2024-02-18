terraform {
  # specify minimum version of Terraform 
  required_version = "> 1.5.4"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #  Lock version to prevent unexpected problems
      version = "5.34.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.24.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }

  }
}

# specify local directory for AWS credentials
provider "aws" {
  region                   = var.region
  shared_credentials_files = ["~/.aws/credentials"]
  #profile                  = var.profile
}
provider "null" {}
provider "external" {}



