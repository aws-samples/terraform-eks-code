resource "aws_ecr_repository" "nginx" {
  name                 = "nginx"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}