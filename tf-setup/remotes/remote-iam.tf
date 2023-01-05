data "terraform_remote_state" "iam" {

  backend = "s3"
  config = {
    bucket = format("tf-state-workshop-%s", var.tfid)
    region = data.aws_region.current.name
    key    = "terraform/terraform_locks_iam.tfstate"
  }
}
