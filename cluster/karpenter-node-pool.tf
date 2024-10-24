resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = file("${path.module}/karpenter-node_pool.yaml")
  depends_on = [kubectl_manifest.karpenter_node_class]
}