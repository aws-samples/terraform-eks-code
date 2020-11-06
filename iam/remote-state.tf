data terraform_remote_state "net" {
backend = "s3"
config = {
bucket = "terraform-state-f8ffc212119c-1604685975n"
region = "eu-west-1"
key = "terraform/at-terraform-eks-workshop1-net.tfstate"
}
}
data terraform_remote_state "iam" {
backend = "s3"
config = {
bucket = "terraform-state-f8ffc212119c-1604685975n"
region = "eu-west-1"
key = "terraform/at-terraform-eks-workshop1-iam.tfstate"
}
}
data terraform_remote_state "c9net" {
backend = "s3"
config = {
bucket = "terraform-state-f8ffc212119c-1604685975n"
region = "eu-west-1"
key = "terraform/at-terraform-eks-workshop1-c9net.tfstate"
}
}
data terraform_remote_state "cluster" {
backend = "s3"
config = {
bucket = "terraform-state-f8ffc212119c-1604685975n"
region = "eu-west-1"
key = "terraform/at-terraform-eks-workshop1-cluster.tfstate"
}
}
