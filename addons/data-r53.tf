# Route53 Hosted Zone Data Source
# Retrieves information about the private hosted zone created in net stage
# Used for External DNS IRSA permissions

data "aws_route53_zone" "phz" {
  # Zone ID from SSM parameter (created by net stage)
  zone_id = data.aws_ssm_parameter.phz-id.value
}

# This data source provides:
# - zone_id: The hosted zone ID
# - arn: The ARN for IAM policy permissions
# - name: The zone name (e.g., account-id.random-id.people.aws.dev)
# - name_servers: The name servers for the zone