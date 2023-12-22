aws route53 list-hosted-zones
hamz=$(aws route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name=="hamster.local.").Id' | cut -f3 -d'/')
rabz=$(aws route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name=="rabbit.local.").Id' | cut -f3 -d'/')
chiz=$(aws route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name=="chipmunk.local.").Id' | cut -f3 -d'/')

aws route53 change-resource-record-sets --hosted-zone-id $rabz --change-batch \ '{"Changes": [ { "Action": "CREATE", "ResourceRecordSet": { "Name": "rabbit.local",   "Type": "A", "AliasTarget":{ "HostedZoneId": "<zone-id-of-ALB>","DNSName": "<DNS-of-ALB>",","EvaluateTargetHealth": false} } } ]}'
aws route53 change-resource-record-sets --hosted-zone-id $hamz --change-batch \ '{"Changes": [ { "Action": "CREATE", "ResourceRecordSet": { "Name": "hamster.local",  "Type": "A", "AliasTarget":{ "HostedZoneId": "<zone-id-of-ALB>","DNSName": "<DNS-of-ALB>",","EvaluateTargetHealth": false} } } ]}'
aws route53 change-resource-record-sets --hosted-zone-id $chiz --change-batch \ '{"Changes": [ { "Action": "CREATE", "ResourceRecordSet": { "Name": "chipmunk.local", "Type": "A", "AliasTarget":{ "HostedZoneId": "<zone-id-of-ALB>","DNSName": "<DNS-of-ALB>",","EvaluateTargetHealth": false} } } ]}'