resource "aws_grafana_workspace_api_key" "key" {
  key_name        = "observability-key"
  key_role        = "ADMIN"
  seconds_to_live = 7200
  workspace_id    = data.aws_ssm_parameter.tf-eks-grafana-id.value
}

