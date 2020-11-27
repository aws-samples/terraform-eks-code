data "aws_subnet" "cicd" {

  filter {
    name   = "tag:workshop"
    values = ["cicd-private1"]
  }
}