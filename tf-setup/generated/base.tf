terraform {
  required_version = "> 1.4.2"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #  Lock version to prevent unexpected problems
      version = "4.43.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.13.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }

  }
  backend "s3" {
    bucket         = local.BUCKET_NAME
    key            = local.BKEY
    region         = local.BREG
    dynamodb_table = local.DTAB
    encrypt        = "true"
  }


}

provider "aws" {
  region                   = var.region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = var.profile
}

provider "null" {}
provider "external" {}








data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "az" {
  state = "available"
}



resource "aws_dynamodb_table" "terraform_lock" {
  # switch var
  name         = format("tf_lock_%s_%s", data.aws_ssm_parameter.tf-eks-id.value, lower(basename(path.cwd)))
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = data.aws_ssm_parameter.tf-eks-keyarn.value
  }

}

