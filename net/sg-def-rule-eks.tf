# Default Security Group Configuration
# Configures the default security group for the EKS VPC
# Note: In production, default SG should be more restrictive

resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  # Allow all traffic from resources in the same security group
  # Enables communication between resources using default SG
  ingress {
    protocol  = -1  # All protocols
    self      = true  # Only from same SG
    from_port = 0
    to_port   = 0
  }

  # Allow all outbound traffic to internet
  # Required for software updates and external API calls
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # All destinations
  }
}



