resource "aws_ec2_instance_metadata_defaults" "eu-west-1" {
  http_endpoint               = "enabled"
  http_tokens                 = "required"
  http_put_response_hop_limit = 3
  instance_metadata_tags      = "disabled"
}



resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
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
  YAML

  depends_on = [
    helm_release.karpenter,aws_ec2_instance_metadata_defaults.eu-west-1
  ]
}

