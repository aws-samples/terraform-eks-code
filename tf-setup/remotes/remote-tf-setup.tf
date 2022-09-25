data "terraform_remote_state" "tf-setup" {

  backend = "s3"
  config = {
    bucket = format("tf-state-workshop-%s", var.tfid)
    region = data.aws_region.current.name
    key    = "terraform/terraform_locks_tf-setup.tfstate"
  }
}