resource "aws_cloud9_environment_ec2" "bastion" {
  instance_type = "t3.small"
  name          = "bastion"
  automatic_stop_time_minutes = "120"
  connection_type = "CONNECT_SSM"
  image_id = "amazonlinux-2-x86_64"
  subnet_id = data.aws_ssm_parameter.sub-priv1.value
  # = format("arn:aws:sts::%s:assumed-role/WSParticipantRole/Participant",data.aws_caller_identity.current.account_id)
  owner_arn=format("arn:aws:sts::%s:assumed-role/WSParticipantRole/Participant",data.aws_caller_identity.current.account_id)
}


resource "aws_cloud9_environment_membership" "bastion" {
  environment_id = aws_cloud9_environment_ec2.bastion.id
  permissions    = "read-write"
  user_arn       =  format("arn:aws:sts::%s:assumed-role/WSParticipantRole/Participant",data.aws_caller_identity.current.account_id)
}