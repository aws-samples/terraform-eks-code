# Grafana API Key
# Creates an API key for automated dashboard provisioning
# Used by AWS Observability Accelerator to create dashboards

resource "aws_grafana_workspace_api_key" "key" {
  # Key name for identification
  key_name        = "observability-key"
  
  # ADMIN role required for dashboard creation and management
  key_role        = "ADMIN"
  
  # Time to live: 5 days (432000 seconds)
  # Short TTL for security - rotate regularly
  seconds_to_live = 432000
  
  # Associated Grafana workspace
  workspace_id    = aws_grafana_workspace.workshop.id
}

# Security Note:
# - This key is stored in AWS Secrets Manager
# - Synced to Kubernetes via External Secrets Operator
# - Used only for automated dashboard provisioning
# - Should be rotated regularly (every 5 days)

