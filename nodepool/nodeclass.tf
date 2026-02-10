# Karpenter NodeClass Configuration
# Defines the infrastructure template for Karpenter-provisioned nodes
# Specifies IAM role, subnets, security groups, and storage configuration

resource "kubectl_manifest" "karpenter_node_class" {
yaml_body = <<-YAML
apiVersion: eks.amazonaws.com/v1
kind: NodeClass
metadata:
  name: mynodeclass
spec:

  # Required: IAM Role for worker nodes
  # Uses the node role created by the cluster stage
  # Provides permissions for EC2, ECR, EKS, and CloudWatch
  role: ${data.aws_ssm_parameter.eks-node-role-name.value}

  # Required: Subnet selection for node placement
  # Uses tag-based selection to find private subnets
  # Tag is applied by VPC module in net stage
  subnetSelectorTerms:
    - tags:
        kubernetes.io/role/internal-elb: "1"
    # Alternative: Direct subnet ID selection
    # - id: "subnet-0123456789abcdef0"

  # Required: Security group selection for nodes
  # Uses the cluster primary security group for control-plane-to-node communication
  securityGroupSelectorTerms:
    # Alternative selection methods:
    #- tags:
    #    Name: my-security-group
    #- name: "my security group name"
    
    # Direct ID reference (recommended for stability)
    - id: ${data.aws_ssm_parameter.cluster-sg.value}

  # Optional: SNAT (Source Network Address Translation) policy
  # Random: Distributes SNAT across available IPs (default)
  # Disabled: No source NAT (requires custom networking setup)
  snatPolicy: Random

  # Optional: Network policy configuration
  # DefaultAllow: All traffic allowed by default (default)
  # DefaultDeny: Requires explicit network policies for traffic
  networkPolicy: DefaultAllow

  # Optional: Network policy event logging
  # Disabled: No logging (default, reduces costs)
  # Enabled: Logs network policy decisions (useful for debugging)
  networkPolicyEventLogs: Disabled

  # Optional: Ephemeral storage configuration
  # This is the root volume for the EC2 instance
  ephemeralStorage:
    size: "80Gi"    # Range: 1-59000Gi or 1-64000G or 1-58Ti or 1-64T
    iops: 3000      # Range: 3000-16000 (gp3 baseline)
    throughput: 125 # Range: 125-1000 MB/s (gp3 baseline)

  # IAM role configuration notes:
  # - If unspecified, EKS creates a default role
  # - If specified (as above), role requires proper access entry
  # - Access entry is configured in cluster stage (podi-association.tf)
  
  # Optional: Additional EC2 instance tags
  # Applied to all instances provisioned by this NodeClass
  # Useful for cost allocation and resource management
  tags:
    Environment: "production"
    Team: "platform"
    Name: "EKS Auto Workshop"
YAML
}