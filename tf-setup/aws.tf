terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
    source = "hashicorp/aws"
    #  Allow any 3.1x version of the AWS provider
    version = "~> 3.22"
    }
    null = {
    source = "hashicorp/null"
    version = "~> 3.0"
    }
    external = {
    source = "hashicorp/external"
    version = "~> 2.0"
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

