# Security Group Rules for VSCode/Cloud9 Instance
# Adds ingress rules to allow traffic from the EKS VPC
# Enables kubectl access and application testing from development environment

# Allow HTTPS from EKS VPC
# Used for secure communication with cluster and applications
resource "aws_security_group_rule" "sg-def-22" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [module.vpc.vpc_cidr_block]
  security_group_id = data.aws_security_group.c9sg.id
}

# Allow SSH from EKS VPC
# Enables SSH access to worker nodes if needed for troubleshooting
resource "aws_security_group_rule" "sg-def-eks-all" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [module.vpc.vpc_cidr_block]
  security_group_id = data.aws_security_group.c9sg.id
}

# Allow port 8080 from the EKS VPC secondary CIDR (nodes, pods, internal load balancers)
# Used for testing applications deployed in the cluster
resource "aws_security_group_rule" "sg-def-eks-8080" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = local.secondary_cidr_blocks
  security_group_id = data.aws_security_group.c9sg.id
}

# Allow HTTP from the EKS VPC secondary CIDR (nodes, pods, internal load balancers)
# Used for testing web applications. Port 80 is also code-server on the IDE instance,
# so it is not opened wider than the EKS VPC (the IDE stack itself allows CloudFront only).
# One CIDR per rule: the CloudFront prefix list on port 80 uses most of this SG's 60-rule quota
resource "aws_security_group_rule" "sg-def-eks-80" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = local.secondary_cidr_blocks
  security_group_id = data.aws_security_group.c9sg.id
}