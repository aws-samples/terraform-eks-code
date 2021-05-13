terraform {
  #required_version = "~> 0.14.10"
  required_version = "= 0.15.3"
  required_providers {
    aws = {
    source = "hashicorp/aws"
    #  Allow only version 3.22
    #version = "= 3.32"
    version = "= 3.39"
    }
    
  }
}

provider "aws" {
  region                  = "eu-west-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "default"
}


