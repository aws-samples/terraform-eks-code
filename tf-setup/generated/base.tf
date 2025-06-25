terraform {
  required_version = "> 1.4.2"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #  Lock version to prevent unexpected problems
      version = "4.43.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.13.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }

  }
  backend "s3" {
    bucket         = local.BUCKET_NAME
    key            = local.BKEY
    region         = local.BREG
    use_lockfile   = true
    encrypt        = true
  }


}

provider "aws" {
  region                   = var.region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = var.profile
}

provider "null" {}
provider "external" {}








data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "az" {
  state = "available"
}


