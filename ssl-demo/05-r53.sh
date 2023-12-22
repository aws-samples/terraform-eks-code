aws route53 list-hosted-zones
aws route53 change-resource-record-sets --hosted-zone-id <Private-hosted-zone-id> --change-batch \ '{"Changes": [ { "Action": "CREATE", "ResourceRecordSet": { "Name": "rabbit.local", "Type": "A", "AliasTarget":{ "HostedZoneId": "<zone-id-of-ALB>","DNSName": "<DNS-of-ALB>",","EvaluateTargetHealth": false} } } ]}'
aws route53 change-resource-record-sets --hosted-zone-id <Private-hosted-zone-id> --change-batch \ '{"Changes": [ { "Action": "CREATE", "ResourceRecordSet": { "Name": "rabbit.local", "Type": "A", "AliasTarget":{ "HostedZoneId": "<zone-id-of-ALB>","DNSName": "<DNS-of-ALB>",","EvaluateTargetHealth": false} } } ]}'
aws route53 change-resource-record-sets --hosted-zone-id <Private-hosted-zone-id> --change-batch \ '{"Changes": [ { "Action": "CREATE", "ResourceRecordSet": { "Name": "rabbit.local", "Type": "A", "AliasTarget":{ "HostedZoneId": "<zone-id-of-ALB>","DNSName": "<DNS-of-ALB>",","EvaluateTargetHealth": false} } } ]}'