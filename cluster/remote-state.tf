data terraform_remote_state "net" {
backend = "s3"
config = {
bucket = "at-terraform-eks-workshop1"
region = "eu-west-1"
key = "terraform/at-terraform-eks-workshop1-net.tfstate"
}
}

data terraform_remote_state "iam" {
backend = "s3"
config = {
bucket = "at-terraform-eks-workshop1"
region = "eu-west-1"
key = "terraform/at-terraform-eks-workshop1-iam.tfstate"
}
}
