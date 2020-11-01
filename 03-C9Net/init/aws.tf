terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "aws" {
  region                  = var.region
  shared_credentials_file = "~/.aws/credentials"
  profile                 = var.profile
  # Allow any 3.1x version of the AWS provider
  version = "~> 3.10"
}