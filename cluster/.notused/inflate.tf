resource "kubectl_manifest" "inflate" {
depends_on = [null_resource.gen_cluster_auth]
yaml_body = <<-YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
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
      terminationGracePeriodSeconds: 0
      containers:
        - name: inflate
          image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
          resources:
            requests:
              memory: 1Gi
          securityContext:
            allowPrivilegeEscalation: false
YAML
}