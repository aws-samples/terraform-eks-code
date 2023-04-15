data "aws_vpc" "eks-vpc" {
  default = false
  id      = data.aws_ssm_parameter.eks-vpc.value
  #filter {
  #  name   = "tag:workshop"
  #  values = ["eks-cicd"]
  #}
}