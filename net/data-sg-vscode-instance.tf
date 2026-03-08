# VSCode/Cloud9 Instance Data Sources
# Discovers the development environment instance and its configuration
# Used to configure security group rules for EKS cluster access

# Find the VSCode Server instance
data "aws_instance" "c9inst" {
  # Filter by instance name tag
  filter {
    name   = "tag:Name"
    values = ["eksworkshop-kiroide"]
  }
  
  # Only find running instances
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# Get the security group attached to the VSCode instance
# sort() ensures consistent selection if multiple SGs exist
data "aws_security_group" "c9sg" {
  name = sort(data.aws_instance.c9inst.vpc_security_group_ids)[0]
}

# Get the IAM instance profile for the VSCode instance
# May be used for additional IAM configuration
data "aws_iam_instance_profile" "c9ip" {
  name = data.aws_instance.c9inst.iam_instance_profile
}







