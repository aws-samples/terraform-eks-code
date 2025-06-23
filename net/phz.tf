resource "aws_route53_zone" "keycloak" {
  name = format("%s.%s.%s",data.aws_caller_identity.current.account_id,data.aws_ssm_parameter.tf-eks-id.value,var.dn)
  
}

#resource "aws_ssm_parameter" "phz-id" {
#name        = "/workshop/tf-eks/phz-id"
#  description = "The id for private hosted zone"
#  type        = "String"
#  value = aws_route53_zone.keycloak.id
#tags = {
#    workshop = "tf-eks-workshop"
#  }
#} 







