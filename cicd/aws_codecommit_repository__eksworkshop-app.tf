resource "aws_codecommit_repository" "eksworkshop-app" {
  repository_name = format("eksworkshop-app-%s",nonsensititive(data.aws_ssm_parameter.tf-eks-id.value))
  description     = "This is the Sample App Repository"
}