data "aws_route53_zone" "phz" {
  zone_id = data.aws_ssm_parameter.phz-id.value
}