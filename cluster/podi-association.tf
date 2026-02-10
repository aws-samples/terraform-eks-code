# EKS Auto Mode Access Configuration
# Configures IAM access for Auto Mode nodes to join and operate in the cluster
# Required for EKS Auto Mode to function properly

# EKS Access Entry for Auto Mode Nodes
# Grants the node IAM role access to the cluster
resource "aws_eks_access_entry" "automode_node" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.eks.node_iam_role_arn
  type          = "EC2"  # EC2 type for Auto Mode compute nodes
}

# EKS Access Policy Association for Auto Mode
# Attaches the AmazonEKSAutoNodePolicy to the node role
# This policy allows Auto Mode to manage node lifecycle
resource "aws_eks_access_policy_association" "automode_node" {
  cluster_name  = module.eks.cluster_name
  
  # AWS managed policy for Auto Mode nodes
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy"
  
  principal_arn = module.eks.node_iam_role_arn
  
  # Cluster-wide access scope
  access_scope {
    type = "cluster"
  }
}