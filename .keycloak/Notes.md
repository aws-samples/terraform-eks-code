https://aws.amazon.com/blogs/containers/serve-distinct-domains-with-tls-powered-by-acm-on-amazon-eks/

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