resource "aws_kms_key" "ekskey" {
  description             = format("EKS KMS Key 2 %s",var.cluster-name)
}