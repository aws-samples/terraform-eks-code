terraform {
  #required_version = "~> 0.14.3"
  required_version = "~> 0.15.3"
  required_providers {
    aws = {
    source = "hashicorp/aws"
    #  Allow any 3.22+  version of the AWS provider
    #version = "~> 3.22"
    version = "= 3.39"
    }
  }
}

provider "aws" {
  region                  = "eu-west-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "default"
}


