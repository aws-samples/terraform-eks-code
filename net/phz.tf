resource "aws_route53_zone" "local" {
  name = var.dn

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

resource "aws_route53_zone_association" "secondary" {
  zone_id = aws_route53_zone.local.zone_id
  vpc_id  = data.aws_vpc.vpc-default.id
}