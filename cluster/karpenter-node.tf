resource "kubectl_manifest" "karpenter_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: default
    spec:
      subnetSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
        Name: karpenter-${module.eks.cluster_name}
      blockDeviceMappings:
        - deviceName: /dev/xvdb
          ebs:
            volumeType: gp2
            volumeSize: 16Gi
            deleteOnTermination: true
      userData: |
        #!/bin/bash
        #yum install -y amazon-ssm-agent
        echo "yum'd agent" >> /tmp/me.txt
        systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
        echo ec2-user:keycloakpass123 | chpasswd || true
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

