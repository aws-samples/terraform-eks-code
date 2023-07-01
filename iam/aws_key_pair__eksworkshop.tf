resource "aws_key_pair" "eksworkshop" {
  key_name   = format("%s-eksworkshop",data.aws_ssm_parameter.tf-eks-id.value)
  public_key = file("~/.ssh/id_rsa.pub")
}

