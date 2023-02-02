data "aws_subnet" "i1" {
  id = data.terraform_remote_state.net.outputs.sub-isol1
}

data "aws_subnet" "i2" {
  id = data.terraform_remote_state.net.outputs.sub-isol2

}

data "aws_subnet" "i3" {
  id = data.terraform_remote_state.net.outputs.sub-isol3

}