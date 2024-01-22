resource "aws_route53_zone" "keycloak" {
  name = format("%s.%s",data.aws_caller_identity.current.account_id,var.dn)
  
}


resource "local_file" "json_config" {
  content         = <<EOF
{
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
}
EOF
  filename        = "/home/ec2-user/environment/${data.aws_caller_identity.current.account_id}-dns.json"
  file_permission = "0640"
}



