
# Network Flow Monitoring Agent Add-on
# Collects VPC flow logs for network traffic analysis
resource "aws_eks_addon" "network-flow-monitoring-agent" {
  cluster_name = data.aws_ssm_parameter.cluster-name.value
  addon_name   = "aws-network-flow-monitoring-agent"
  
  # Features:
  # - VPC flow logs for pod-to-pod traffic
  # - Network security analysis
  # - Troubleshooting connectivity issues
  # - Integration with CloudWatch Logs
}