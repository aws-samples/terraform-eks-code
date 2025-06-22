resource "kubectl_manifest" "karpenter_node_pool2" {
depends_on = [kubectl_manifest.karpenter_node_class]
yaml_body = <<-YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: my-node-pool2
spec:
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
    expireAfter: 48h # 4 days
    budgets:
    - nodes: "50%"  
      schedule: "0 2 * * *"  # daily at 2am UTC
      duration: "3h"        # 1 hour
  template:
    metadata:
      labels:
        billing-team: my-team
    spec:
      nodeClassRef:
        group: eks.amazonaws.com
        kind: NodeClass
        name: mynodeclass
      requirements:
        - key: "eks.amazonaws.com/instance-category"
          operator: In
          values: ["c", "m", "r"]
        - key: "eks.amazonaws.com/instance-cpu"
          operator: In
          values: ["4", "8", "16", "32"]
        - key: "topology.kubernetes.io/zone"
          operator: In
          values: ["eu-west-1a", "eu-west-1b","eu-west-1c"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: eks.amazonaws.com/instance-generation
          operator: Gt
          values: ["5"]
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["on-demand","spot"]
  limits:
    cpu: "1000"
    memory: 1000Gi
YAML
}


