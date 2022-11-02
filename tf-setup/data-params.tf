data "aws_ssm_parameter" "tf-eks-id" {
  name        = "/workshop/tf-eks/id"


data "aws_ssm_parameter" "tf-eks-keyid" {
  name        = "/workshop/tf-eks/keyid"

}

data "aws_ssm_parameter" "tf-eks-region" {
  name        = "/workshop/tf-eks/region"
}