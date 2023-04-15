resource "aws_cloud9_environment_ec2" "bastion" {
  instance_type = "t3.small"
  name          = "bastion"
  automatic_stop_time_minutes = "120"
  connection_type = "CONNECT_SSM"
  image_id = "amazonlinux-2-x86_64"
  subnet_id = data.aws_ssm_parameter.sub-isol1.value
}