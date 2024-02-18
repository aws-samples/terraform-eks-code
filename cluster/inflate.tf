# Example deployment using the [pause image](https://www.ianlewis.org/en/almighty-pause-container)
# and starts with zero replicas
resource "kubernetes_namespace_v1" "other" {
  metadata {
    name = "other"
  }
}

resource "kubectl_manifest" "karpenter_example_deployment" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: inflate
      namespace: other
    spec:
      replicas: 0
      selector:
        matchLabels:
          app: inflate
      template:
        metadata:
          labels:
            app: inflate
        spec:
          nodeSelector:
            karpenter.sh/capacity-type: spot
          terminationGracePeriodSeconds: 0
          containers:
            - name: inflate
              image: public.ecr.aws/eks-distro/kubernetes/pause:3.2
              resources:
                requests:
                  memory: 1Gi
          priorityClassName: low-priority
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

