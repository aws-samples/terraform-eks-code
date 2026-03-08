# Get the security group attached to the VSCode instance
# sort() ensures consistent selection if multiple SGs exist
data "aws_security_group" "c9sg" {
  name = sort(data.aws_instance.c9inst.vpc_security_group_ids)[0]
}








