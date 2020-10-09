data "external" "describe_organization" {
  program = ["bash", "${path.module}/describeOrganization.sh"]
}

output "Id" {
  value = data.external.describe_organization.result.Id
}
