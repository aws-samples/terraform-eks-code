terraform {

  required_version = "~> 1.3.7"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #  Allow only version 4.53
      version = "= 4.53.0"
    }
  }
}

provider "aws" {
  region                   = var.region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
}

variable "region" {
  description = "The name of the AWS Region"
  type        = string
  default     = "eu-west-1"
}




