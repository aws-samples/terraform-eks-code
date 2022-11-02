locals {
  BUCKET_NAME = "tf-state-workshop-${data.aws_ssm_parameter.tf-eks-id.value}"  
  BKEY="terraform/terraform_locks_${lower(basename(path.cwd))}.tfstate"
  BREG="${data.aws_region.current.name}"
  DTAB="terraform_locks_${lower(basename(path.cwd))}"
}