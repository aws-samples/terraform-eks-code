data "aws_route_table" "cicd-rtb" {
  vpc_id=aws_vpc.vpc-cicd.id
  filter {
    name   = "tag:Name"
    values = ["rtb-eks-cicd-priv1"]
  }
}







