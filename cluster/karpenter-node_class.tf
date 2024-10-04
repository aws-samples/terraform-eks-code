resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2023
      role: ${module.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      amiSelectorTerms:
    #    - id: "${ARM_AMI_ID}"
    #    - id: "${AMD_AMI_ID}"
    #   - id: "${GPU_AMI_ID}" # <- GPU Optimized AMD AMI 
        - name: "amazon-eks-node-${data.aws_ssm_parameter.tf-eks-version.value}-*" # <- automatically upgrade when a new AL2 EKS Optimized AMI is released. This is unsafe for production workloads. Validate AMIs in lower environments before deploying them to production.
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

