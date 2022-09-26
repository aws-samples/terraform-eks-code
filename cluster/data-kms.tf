data "aws_kms_key" "ekskey" {
 
  key_id=var.keyid
}