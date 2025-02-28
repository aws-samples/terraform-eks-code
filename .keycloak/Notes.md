https://aws.amazon.com/blogs/containers/serve-distinct-domains-with-tls-powered-by-acm-on-amazon-eks/

Keycloak cli
https://github.com/adorsys/keycloak-config-cli?tab=readme-ov-file

--------------

$ kubectl -n keycloak exec -it $(kubectl get pod -n keycloak -o json | jq -r '.items[].metadata.name') -- /bin/bash                                                                         
bash-4.4$ cd /opt/keycloak/bin/ 
bash-4.4$ ls
client  kcadm.bat  kcadm.sh  kc.bat  kcreg.bat  kcreg.sh  kc.sh

bash-4.4$ ./kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password keycloakpass123
Logging into http://localhost:8080 as user admin of realm master
Enter password: ***************
bash-4.4$ ./kcadm.sh update realms/master -s sslRequired=NONE

bash-4.4$ exit

bash-4.4$ ./kcadm.sh create realms -f - << EOF
{ "realm": "demorealm", "enabled": true }
EOF

-----------------

kubectl -n keycloak exec -it $(kubectl get pod -n keycloak -o json | jq -r '.items[].metadata.name') -- /bin/bash -c "cd /opt/keycloak/bin/ && 
./kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password keycloakpass123 && exit"
kubectl exec -it sss-pod-four  -- bash -c "echo hi > /mnt/sss/testnew.txt" 

kubectl port-forward keycloak-7f8c46dfb-72xrp 8080:8080
put public ip for LB in /etc/hosts   for   keycloak.testdomain.local
config preview URL to keycloak.testdomain.local






preview app (open in new window)


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




aws route53 change-resource-record-sets \
  --hosted-zone-id $zoneid \
  --change-batch '{
          "Comment": "CREATE NS a record ",
          "Changes": [{
          "Action": "CREATE",
                "ResourceRecordSet": {
                                    "Name": "571596003809.awsandy.people.aws.dev",
                                    "Type": "NS",
                                    "TTL": 300,
                                 "ResourceRecords": [
                                  {"Value": "ns-1482.awsdns-57.org"},
                                  {"Value": "ns-180.awsdns-22.com"},
                                  {"Value": "ns-1946.awsdns-51.co.uk"},
                                  {"Value": "ns-837.awsdns-40.net"}
                                  ]
          }}]
}'


