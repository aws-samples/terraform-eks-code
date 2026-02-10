# Route53 Private Hosted Zone
# Creates a private hosted zone for internal DNS resolution
# Used for Keycloak authentication and internal service discovery

resource "aws_route53_zone" "keycloak" {
  # Zone name format: {account-id}.{random-id}.{domain}
  # Example: 123456789012.a1b2c3d4e5f6g7h8.people.aws.dev
  # Ensures unique zone name across deployments
  name = format("%s.%s.%s",data.aws_caller_identity.current.account_id,data.aws_ssm_parameter.tf-eks-id.value,var.dn)
}

# SSM parameter for hosted zone ID
# Moved to ssm-params-net.tf for better organization
#resource "aws_ssm_parameter" "phz-id" {
#  name        = "/workshop/tf-eks/phz-id"
#  description = "The id for private hosted zone"
#  type        = "String"
#  value       = aws_route53_zone.keycloak.id
#  tags = {
#    workshop = "tf-eks-workshop"
#  }
#} 







