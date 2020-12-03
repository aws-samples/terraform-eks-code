#
# Outputs
#

locals {
  config-map-aws-auth = <<CONFIGMAPAWSAUTH
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: data.terraform_remote_state.iam.outputs.nodegroup_role_arn
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: aws_eks_cluster.eks-cluster.endpoint
    certificate-authority-data: aws_eks_cluster.eks-cluster.certificate_authority.0.data
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "aws_eks_cluster.eks-cluster.name"
KUBECONFIG
}

output "config-map-aws-auth" {
  value = "local.config-map-aws-auth"
}

output "kubeconfig" {
  value = "local.kubeconfig"
}

