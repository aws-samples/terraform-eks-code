terraform {
  required_version = "~> 1.1.0"
  required_providers {
    aws = {
    source = "hashicorp/aws"
    #  Lock version to prevent unexpected problems
    version = "3.69"
    }
    null = {
    source = "hashicorp/null"
    version = "~> 3.1.0"
    }
    external = {
    source = "hashicorp/external"
    version = "~> 2.1.0"
    }
    kubernetes = {
    source = "hashicorp/kubernetes"
    version = "2.7.1"
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

