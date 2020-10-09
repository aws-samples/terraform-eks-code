provider "aws" {
  region                  = "eu-west-2"
  shared_credentials_file = "~/.aws/credentials"
  version                 = "= 3.8.0"
  profile                 = "default"
}
