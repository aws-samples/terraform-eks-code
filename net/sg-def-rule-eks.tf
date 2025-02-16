resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress_ipv6 {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["::/0"]
  }
}


