#resource "aws_route53_zone" "keycloak" {
#  name         = format("%s.%s",data.aws_caller_identity.current.account_id,var.dn)
#}





#resource "aws_route53_record" "dev-ns" {
#  zone_id = aws_route53_zone.main.zone_id
#  name    = "dev.example.com"
#  type    = "NS"
#  ttl     = "30"
#  records = aws_route53_zone.dev.name_servers
#}