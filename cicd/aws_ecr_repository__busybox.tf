resource "aws_ecr_repository" "busybox" {
  name                 = "busybox"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}