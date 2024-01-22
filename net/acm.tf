resource "aws_acm_certificate" "keycloak" {
  domain_name = format("keycloak.%s",aws_route53_zone.keycloak.id)
  validation_method = "DNS"
}


resource "aws_route53_record" "keycloak" {
  for_each = {
    for dvo in aws_acm_certificate.keycloak.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = aws_route53_zone.keycloak.id
}

resource "aws_acm_certificate_validation" "keycloak" {     ## should take ~ 3 minutes
  certificate_arn         = aws_acm_certificate.keycloak.arn
  validation_record_fqdns = [for record in aws_route53_record.keycloak : record.fqdn]
}