data terraform_remote_state "c9net" {
backend = "s3"
config = {
bucket = "terraform-state-f8ffc212119c-1604685411n"
region = "eu-west-1"
key = "terraform/at-terraform-eks-workshop1-c9net.tfstate"
}
}
