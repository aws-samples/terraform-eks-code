# Default StorageClass Configuration
# Defines the default storage class for persistent volume claims
# Uses EBS CSI driver with gp3 volumes and encryption

resource "kubectl_manifest" "storage" {
yaml_body = <<-YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: auto-ebs-sc
  annotations:
    # Mark this as the default storage class
    # PVCs without a storageClassName will use this class
    storageclass.kubernetes.io/is-default-class: "true"

# EBS CSI driver provisioner
# Requires EBS CSI driver add-on to be installed
provisioner: ebs.csi.eks.amazonaws.com

# Volume binding mode
# WaitForFirstConsumer: Delays volume creation until pod is scheduled
# Ensures volume is created in the same AZ as the pod
# Alternative: Immediate (creates volume immediately, may be in wrong AZ)
volumeBindingMode: WaitForFirstConsumer

# Volume parameters
parameters:
  # Volume type: gp3 (General Purpose SSD v3)
  # gp3 advantages over gp2:
  # - 20% cheaper
  # - Baseline: 3000 IOPS, 125 MB/s throughput
  # - Can scale IOPS/throughput independently
  type: gp3
  
  # Encryption: Enabled by default
  # Uses default EBS encryption key or KMS key if configured
  encrypted: "true"
YAML
}

