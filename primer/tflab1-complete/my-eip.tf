resource "aws_eip" "my-eip" {
  public_ipv4_pool = "amazon"
  tags             = {}
  vpc              = true
  timeouts {}
}