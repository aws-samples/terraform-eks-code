# AWS Managed EKS Add-ons
# These add-ons are managed by AWS and automatically updated
# Installed directly via aws_eks_addon resource

# CloudWatch Observability Add-on
# Provides Container Insights, application signals, and log collection
resource "aws_eks_addon" "cloudwatch-observability" {
  cluster_name = data.aws_ssm_parameter.cluster-name.value
  addon_name   = "amazon-cloudwatch-observability"
  
  # Features:
  # - Container Insights: Pod and node metrics
  # - Application Signals: Application performance monitoring
  # - Log Collection: Container logs to CloudWatch
  # - Pre-built dashboards in CloudWatch
}

# Metrics Server Add-on
# Provides resource metrics for HPA and kubectl top commands
resource "aws_eks_addon" "metrics-server" {
  cluster_name = data.aws_ssm_parameter.cluster-name.value
  addon_name   = "metrics-server"
  
  # Features:
  # - CPU and memory metrics for nodes and pods
  # - Enables Horizontal Pod Autoscaler (HPA)
  # - Enables kubectl top nodes/pods commands
  # - Required for cluster autoscaling
}

