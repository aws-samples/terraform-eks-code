resource "kubectl_manifest" "karpenter_node_class" {
    yaml_body = file("${path.module}/karpenter-node_class.yaml")
    depends_on = [helm_release.karpenter,aws_ec2_instance_metadata_defaults.metadata]
}