data "terraform_remote_state" "tf-setup" {
  depends_on=[null_resource.gen_idfile,aws_s3_bucket.terraform_state]
  backend = "s3"
  config = {
    bucket = format("tf-state-workshop-%s", var.tfid)
    region = data.aws_region.current.name
    key    = "terraform/terraform_locks_tf-setup.tfstate"
  }
}