# Grafana API Key
# Creates an API key for automated dashboard provisioning
# Used by AWS Observability Accelerator to create dashboards

resource "aws_grafana_workspace_api_key" "key" {
  # Key name for identification
  key_name = "observability-key"

  # ADMIN role required for dashboard creation and management
  key_role = "ADMIN"

  # Time to live: 5 days (432000 seconds)
  # Short TTL for security - rotate regularly
  seconds_to_live = 432000

  # Associated Grafana workspace
  workspace_id = aws_grafana_workspace.workshop.id
}

# Security Note:
# - Used by the Grafana Terraform provider (main.tf) to create the folder, dashboards and data source
# - Held in Terraform state (S3, KMS-encrypted); not synced into the cluster (v3 has no External Secrets)
# - Expires after 5 days; plans in this stage then fail until it is recreated:
#     terraform apply -replace=aws_grafana_workspace_api_key.key

