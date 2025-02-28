data "aws_route53_zone" "keycloak" {
  zone_id = data.aws_ssm_parameter.phz-id.value
}