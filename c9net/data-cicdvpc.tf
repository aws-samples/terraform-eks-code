data "aws_vpc" "vpc-cicd" {
  default = false
  id      = data.aws_ssm_parameter.cicd-vpc
  #filter {
  #  name   = "tag:workshop"
  #  values = ["eks-cicd"]
  #}
}
