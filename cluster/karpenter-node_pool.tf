resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
        kind: NodePool
        metadata:
          name: default
        spec:
          template:
            spec:
              nodeClassRef:
                name: default
              requirements:
                - key: kubernetes.io/arch
                  operator: In
                  values: ["amd64"]
                - key: kubernetes.io/os
                  operator: In
                  values: ["linux"]
                - key: "karpenter.k8s.aws/instance-category"
                  operator: In
                  values: ["c", "m", "r"]
                - key: "karpenter.k8s.aws/instance-cpu"
                  operator: In
                  values: ["4", "8", "16", "32"]
                - key: "karpenter.k8s.aws/instance-hypervisor"
                  operator: In
                  values: ["nitro"]
                - key: "karpenter.k8s.aws/instance-generation"
                  operator: Gt
                  values: ["4"]
              nodeClassRef:
                group: karpenter.k8s.aws
                kind: EC2NodeClass
                name: default
            expireAfter: 720h # 30 * 24h = 720h
          limits:
            cpu: 1000
          disruption:
            consolidationPolicy: WhenEmpty
            consolidateAfter: 30s
  YAML
  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

