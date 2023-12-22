defvpc=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query 'Vpcs[].VpcId' --output text)
#hamz=$(aws route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name=="hamster.local.").Id' | cut -f3 -d'/')
rabz=$(aws route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name=="rabbit.local.").Id' | cut -f3 -d'/')
#chiz=$(aws route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name=="chipmunk.local.").Id' | cut -f3 -d'/')
#aws route53 associate-vpc-with-hosted-zone --hosted-zone-id $hamz --vpc VPCRegion=eu-west-1,VPCId=$defvpc --region eu-west-1
aws route53 associate-vpc-with-hosted-zone --hosted-zone-id $rabz --vpc VPCRegion=eu-west-1,VPCId=$defvpc --region eu-west-1
#aws route53 associate-vpc-with-hosted-zone --hosted-zone-id $chiz --vpc VPCRegion=eu-west-1,VPCId=$defvpc --region eu-west-1
