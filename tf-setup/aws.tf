terraform {
  required_version = ">= 0.14"
  required_providers {
    aws {
    source = "hashicord/aws"
    #  Allow any 3.1x version of the AWS provider
    version = "~> 3.22"
  }
}

provider "aws" {
  region                  = var.region
  shared_credentials_file = "~/.aws/credentials"
  profile                 = var.profile
}