# Get the security group attached to the VSCode instance
# sort() ensures consistent selection if multiple SGs exist
data "aws_security_group" "c9sg" {
  filter {
    name   = "tag:Name"
    values = ["Kiro1-Instance-SG"]
  }
}








