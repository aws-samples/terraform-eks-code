data "external" "find_ou" {
  program = ["bash", "${path.module}/listOU.sh"]

  query = {
    parent_id = var.parent_id
    ou_name   = var.ou_name
    profile   = var.profile
  }
}

output "Id" {
  value = data.external.find_ou.result.Id
}
