resource "kubectl_manifest" "karpenter_node_class" {
depends_on = [null_resource.gen_cluster_auth]
yaml_body = <<-YAML
apiVersion: eks.amazonaws.com/v1
kind: NodeClass
metadata:
  name: mynodeclass
spec:

  # Required: Name of IAM Role for Nodes
  role: ${module.eks.node_iam_role_name}

  # Required: Subnet selection for node placement
  subnetSelectorTerms:
    - tags:
        kubernetes.io/role/internal-elb: "1"
    # Alternative using direct subnet ID
    # - id: "subnet-0123456789abcdef0"

  # Required: Security group selection for nodes
  securityGroupSelectorTerms:
    #- tags:
    #    Name: 
    # Alternative approaches:
    #- id: "sg-04b04505d2d96d877"
    #- name: ${data.aws_security_group.primary_eks_sec_grp.name}
    - id: ${module.eks.cluster_primary_security_group_id}


  # Optional: Configure SNAT policy (defaults to Random)
  snatPolicy: Random  # or Disabled

  # Optional: Network policy configuration (defaults to DefaultAllow)
  networkPolicy: DefaultAllow  # or DefaultDeny

  # Optional: Network policy event logging (defaults to Disabled)
  networkPolicyEventLogs: Disabled  # or Enabled

  # Optional: Configure ephemeral storage (shown with default values)
  ephemeralStorage:
    size: "80Gi"    # Range: 1-59000Gi or 1-64000G or 1-58Ti or 1-64T
    iops: 3000      # Range: 3000-16000
    throughput: 125 # Range: 125-1000

  # IAM role to use for EC2 instance role
  # If unspecified, EKS will create a role
  # If specified, role requires access entry described above
  #role: arn:aws:iam::123456789012:role/MyNodeRole
  #role: module.eks.node_iam_role_arn
  
  # Optional: Additional EC2 tags
  tags:
    Environment: "production"
    Team: "platform"
YAML
}