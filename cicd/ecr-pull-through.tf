resource "aws_ecr_pull_through_cache_rule" "aws" {
  ecr_repository_prefix = "aws"
  upstream_registry_url = "public.ecr.aws"
}

#resource "aws_ecr_pull_through_cache_rule" "quay" {
#  ecr_repository_prefix = "quay"
#  upstream_registry_url = "quay.io"
#}