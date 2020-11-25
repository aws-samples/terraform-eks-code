resource "aws_codecommit_repository" "eksworkshop-app" {
  repository_name = "eksworkshop-app"
  description     = "This is the Sample App Repository"
}