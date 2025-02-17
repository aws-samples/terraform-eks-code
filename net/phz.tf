resource "aws_route53_zone" "keycloak" {
  name = format("%s.%s.%s",data.aws_caller_identity.current.account_id,var.awsalias,var.dn)
  
}

#resource "aws_ssm_parameter" "phz-id" {
#name        = "/workshop/tf-eks/phz-id"
#  description = "The id for private hosted zone"
#  type        = "String"
#  value = aws_route53_zone.keycloak.id
#tags = {
#    workshop = "tf-eks-workshop"
#  }
#} 


resource "local_file" "json_config" {
  content         = <<EOF
aws route53 change-resource-record-sets \
  --hosted-zone-id $zoneid \
  --change-batch '{
          "Comment": "CREATE NS a record ",
          "Changes": [{
          "Action": "CREATE",
                "ResourceRecordSet": {
                                    "Name": "${aws_route53_zone.keycloak.name}",
                                    "Type": "NS",
                                    "TTL": 300,
                                 "ResourceRecords": [
                                  {"Value": "${aws_route53_zone.keycloak.name_servers[0]}"},
                                  {"Value": "${aws_route53_zone.keycloak.name_servers[1]}"},
                                  {"Value": "${aws_route53_zone.keycloak.name_servers[2]}"},
                                  {"Value": "${aws_route53_zone.keycloak.name_servers[3]}"}
                                  ]
          }}]
}'
EOF
  filename        = "/home/ec2-user/environment/setup-${data.aws_caller_identity.current.account_id}-dns.sh"
  file_permission = "0640"
}




