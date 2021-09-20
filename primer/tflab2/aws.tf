terraform {
  #required_version = "~> 0.14.10"
  required_version = "~> 1.0.0"
  required_providers {
    aws = {
    source = "hashicorp/aws"
    #  Allow only version 3.22
    version = "= 3.39"
    }   
  }
}

provider "aws" {
  region                  = var.region
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "default"
}

variable "region" {
  description = "The name of the AWS Region"
  type        = string
  default     = "eu-west-1"
}




