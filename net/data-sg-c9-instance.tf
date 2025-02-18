data "aws_instance" "c9inst" {

  filter {
    name   = "tag:Name"
    values = ["VSCodeServer"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }


}

data "aws_security_group" "c9sg" {
  name = sort(data.aws_instance.c9inst.security_groups)[0]
}


data "aws_iam_instance_profile" "c9ip" {
  name = data.aws_instance.c9inst.iam_instance_profile
}

output "c9role" {
  value = data.aws_iam_instance_profile.c9ip.role_arn
}






