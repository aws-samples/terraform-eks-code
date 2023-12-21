resource "aws_route53_zone" "private" {
  name = "example.com"

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}