terraform {

  required_version = "~> 1.4.4"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #  Allow only version 4.63
      version = "= 4.65.0"
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




