# AWS Account and Region Data Sources
# Provides context about the deployment environment

# Current AWS region
data "aws_region" "current" {}

# Current AWS account ID and caller identity
# Used for KMS key ownership and IAM policies
data "aws_caller_identity" "current" {}