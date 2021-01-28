resource "aws_ecr_repository" "aws-cli" {
  name                 = "aws-cli"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}