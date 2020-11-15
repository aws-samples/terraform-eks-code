provider "aws" {
  region                  = "eu-west-1"
  shared_credentials_file = "~/.aws/credentials"
  version                 = "~> 3.12"
  profile                 = "default"
}
