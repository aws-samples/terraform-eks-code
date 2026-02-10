# Additional IAM Policies for Node Role
# Attaches extra policies to the Auto Mode node IAM role
# These policies enable additional functionality beyond basic EKS operations

# CloudWatch Agent Server Policy
# Allows nodes to send metrics and logs to CloudWatch
# Required for observability and monitoring
resource "aws_iam_role_policy_attachment" "additional_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = module.eks.node_iam_role_name
}

# Policies NOT needed for Auto Mode (already included or managed differently):
# - AmazonInspector2ManagedCisPolicy: Security scanning (optional)
# - AmazonSSMManagedInstanceCore: SSM access (Auto Mode handles this)
# - AmazonEKSWorkerNodePolicy: Already included in Auto Mode
# - AmazonEC2ContainerRegistryReadOnly: Already included in Auto Mode
# - AmazonEBSCSIDriverPolicy: Managed separately as EKS add-on