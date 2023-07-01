data "aws_subnet" "i1" {
  id = data.aws_ssm_parameter.sub-isol1.value
}

data "aws_subnet" "i2" {
  id = data.aws_ssm_parameter.sub-isol2.value

}

data "aws_subnet" "i3" {
  id = data.aws_ssm_parameter.sub-isol3.value
  
}