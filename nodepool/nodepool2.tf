# Karpenter NodePool Configuration
# Defines scheduling requirements, instance selection, and disruption policies
# This is the main configuration that determines what nodes Karpenter provisions

# Fetch available AZs for the current region
# Used to dynamically populate zone requirements in NodePool
data "aws_availability_zones" "available" {
  state = "available"
  
  # Filter out Local Zones and Wavelength Zones
  # Only use standard availability zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Karpenter NodePool Resource
# Depends on NodeClass being created first
resource "kubectl_manifest" "karpenter_node_pool2" {
depends_on = [kubectl_manifest.karpenter_node_class]
yaml_body = <<-YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: my-node-pool2
spec:
  # Disruption policies control node lifecycle and cost optimization
  disruption:
    # Consolidation: Remove underutilized nodes to reduce costs
    # WhenEmpty: Only consolidate when node is completely empty
    # WhenUnderutilized: More aggressive, consolidates underutilized nodes
    consolidationPolicy: WhenEmpty
    
    # Wait 30 seconds after node becomes empty before consolidating
    # Prevents thrashing if pods are quickly rescheduled
    consolidateAfter: 30s
    
    # Expire nodes after 48 hours (2 days)
    # Ensures nodes get latest AMI updates and prevents long-running issues
    expireAfter: 48h
    
    # Disruption budgets control rate of node disruption
    budgets:
    - nodes: "50%"              # Maximum 50% of nodes can be disrupted
      schedule: "0 2 * * *"     # Daily at 2am UTC (cron format)
      duration: "3h"            # 3-hour maintenance window
  
  # Template defines node configuration
  template:
    metadata:
      # Labels applied to all nodes created by this NodePool
      # Useful for cost allocation and pod scheduling
      labels:
        billing-team: my-team
    
    spec:
      # Reference to NodeClass for infrastructure configuration
      nodeClassRef:
        group: eks.amazonaws.com
        kind: NodeClass
        name: mynodeclass
      
      # Requirements define instance selection criteria
      # Karpenter chooses the cheapest instance that satisfies all requirements
      requirements:
        # Instance categories (families)
        # c: Compute-optimized (CPU-intensive workloads)
        # m: General-purpose (balanced compute/memory)
        # r: Memory-optimized (memory-intensive workloads)
        - key: "eks.amazonaws.com/instance-category"
          operator: In
          values: ["c", "m", "r"]
        
        # Instance sizes (vCPUs)
        # Provides flexibility for Karpenter to choose optimal size
        # Examples: c5.xlarge (4), m5.2xlarge (8), r5.4xlarge (16)
        - key: "eks.amazonaws.com/instance-cpu"
          operator: In
          values: ["4", "8", "16", "32"]
        
        # Availability zones
        # Dynamically populated from data source
        # Ensures high availability across all zones
        - key: "topology.kubernetes.io/zone"
          operator: In
          values: ${jsonencode(data.aws_availability_zones.available.names)}
        
        # CPU architecture
        # amd64: x86_64 (broader application compatibility)
        # arm64: Graviton (better price/performance, requires compatible images)
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        
        # Instance generation
        # Gt (greater than) 5: Only use generation 6+ instances
        # Modern instances have better performance and price/performance
        # Examples: c6i, m6i, r6i (generation 6)
        - key: eks.amazonaws.com/instance-generation
          operator: Gt
          values: ["5"]
        
        # Capacity type
        # on-demand: Guaranteed capacity, higher cost
        # spot: Up to 90% discount, can be interrupted with 2-min notice
        # Karpenter automatically handles spot interruptions
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["on-demand","spot"]
  
  # Resource limits prevent runaway scaling
  # Applied across all nodes in this NodePool
  limits:
    cpu: "1000"      # Maximum 1000 CPU cores total
    memory: 1000Gi   # Maximum 1000Gi memory total
YAML
}


