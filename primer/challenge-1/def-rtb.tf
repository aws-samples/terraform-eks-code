data "aws_route_table" "defrt" { 
  #subnet_id=data.aws_subnet.c9subnet.id
  #filter {
  #  values = [ data.aws_subnet.c9subnet.id ]
  ##  name = "association.subnet-id"
  #}
  route_table_id=var.rtbid
}