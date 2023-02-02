resource "aws_kms_key" "ekskey" {
  description = format("EKS KMS Key 2 %s", var.cluster-name)
}

output "keyid" {
  value = aws_kms_key.ekskey.key_id
}