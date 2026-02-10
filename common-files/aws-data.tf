# AWS Account and Region Data Sources
# These provide context about the deployment environment

# Current AWS region being used
data "aws_region" "current" {}

# Current AWS account ID and caller identity
data "aws_caller_identity" "current" {}

# Available availability zones in the current region
# Used by subsequent stages for multi-AZ deployments
data "aws_availability_zones" "az" {
  state = "available"
}

# ECR Public authorization token - currently not used
#data "aws_ecrpublic_authorization_token" "token" {}
