resource "aws_eip" "my-eip" {
  count            = var.mycount
  public_ipv4_pool = "amazon"
  tags             = {}
  vpc              = true
  timeouts {}
}
