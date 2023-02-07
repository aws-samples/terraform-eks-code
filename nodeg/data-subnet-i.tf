data "aws_subnet" "i1" {
  id = data.aws_ssm_parameter.sub-isol1
}

data "aws_subnet" "i2" {
  id = data.aws_ssm_parameter.sub-isol2

}

data "aws_subnet" "i3" {
  id = data.aws_ssm_parameter.sub-isol3

}