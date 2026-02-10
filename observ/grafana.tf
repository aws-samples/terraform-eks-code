resource "aws_grafana_workspace" "workshop"  {
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML"]
  permission_type          = "CUSTOMER_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn
  name = "keycloak-blog"     # must match  keycloak stuff
}

# IAM Role for Grafana Workspace
# Allows Grafana service to assume this role and access AWS data sources

resource "aws_iam_role" "grafana" {
  name = "grafana-assume"
  
  # Trust policy: Allow Grafana service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      },
    ]
  })
}

# IAM Policy Attachments for Grafana Data Sources
# Grants Grafana read-only access to AWS monitoring services

# Amazon Managed Prometheus access
# Allows Grafana to query AMP workspaces for metrics
resource "aws_iam_role_policy_attachment" "prom-attach" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
}

# CloudWatch access
# Allows Grafana to query CloudWatch metrics and logs
resource "aws_iam_role_policy_attachment" "cw-attach" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonGrafanaCloudWatchAccess"
}

# AWS X-Ray access
# Allows Grafana to visualize distributed traces
resource "aws_iam_role_policy_attachment" "xray-attach" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess"
}

