terraform {
  required_version = "~> 1.0.0"
  required_providers {
    aws = {
    source = "hashicorp/aws"
    #  Lock version to prevent unexpected problems
    version = "3.46"
    }
    null = {
    source = "hashicorp/null"
    version = "~> 3.0"
    }
    external = {
    source = "hashicorp/external"
    version = "~> 2.0"
    }
    kubernetes = {
    source = "hashicorp/kubernetes"
    version = "1.13.3"
    }
    
  }
}

provider "aws" {
  region                  = var.region
  shared_credentials_file = "~/.aws/credentials"
  profile                 = var.profile
}
provider "null" {}
provider "external" {}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "az" {
  state = "available"
}

