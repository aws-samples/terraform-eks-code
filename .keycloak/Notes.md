https://aws.amazon.com/blogs/containers/serve-distinct-domains-with-tls-powered-by-acm-on-amazon-eks/

Keycloak cli
https://github.com/adorsys/keycloak-config-cli?tab=readme-ov-file





docker run \
    -e KEYCLOAK_URL="http://<your keycloak host>:8080/" \
    -e KEYCLOAK_USER="<keycloak admin username>" \
    -e KEYCLOAK_PASSWORD="<keycloak admin password>" \
    -e KEYCLOAK_AVAILABILITYCHECK_ENABLED=true \
    -e KEYCLOAK_AVAILABILITYCHECK_TIMEOUT=120s \
    -e IMPORT_FILES_LOCATIONS='/config/*' \
    -v <your config path>:/config \
    adorsys/keycloak-config-cli:latest



## -v local config dir to docker directory /config


aws route53 change-resource-record-sets --hosted-zone-id <Private-hosted-zone-id> --change-batch \ '{"Changes": [ { "Action": "CREATE", "ResourceRecordSet": { "Name": "rabbit.local", "Type": "A", "AliasTarget":{ "HostedZoneId": "<zone-id-of-ALB>","DNSName": "<DNS-of-ALB>",","EvaluateTargetHealth": false} } } ]}'

    aws route53 change-resource-record-sets --hosted-zone-id <Private-hosted-zone-id> --change-batch \ 
    
{
    "Changes": [
        { 
            "Action": "CREATE", 
            "ResourceRecordSet": { 
                "Name": "rabbit.local", 
                "Type": "A", 
                "AliasTarget": { 
                    "HostedZoneId": "<zone-id-of-ALB>",
                    "DNSName": "<DNS-of-ALB>",
                    "EvaluateTargetHealth" : false
                } 
            } 
        }
    ]
}


aws route53 change-resource-record-sets --hosted-zone-id Z013560735H8VUPXL2MHI --change-batch '{"Changes": [ { "Action": "CREATE", "ResourceRecordSet": { "Name": "Z32O12XQLNTSW2", "Type": "A", "AliasTarget":{ "HostedZoneId": "k8s-default-ingressk-7fa2167de4-1928413011.eu-west-1.elb.amazonaws.com","DNSName": "", "EvaluateTargetHealth": false } } } ]}'