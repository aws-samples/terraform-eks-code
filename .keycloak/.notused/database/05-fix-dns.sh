#kchn="keycloak.testdomain.local"
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export HOSTED_ZONE=$ACCOUNT_ID.awsandy.people.aws.dev
domain=$ACCOUNT_ID.awsandy.people.aws.dev
reg=$(aws configure get region)
vpcid=$(aws ssm get-parameter --name /workshop/tf-eks/eks-vpc --query Parameter.Value --output text)
keyz=$(aws route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name=="'$domain'.").Id' | cut -f3 -d'/')
kchn=$(echo keycloak.$ACCOUNT_ID.awsandy.people.aws.dev)
lbhn=$(kubectl -n keycloak get ingress -o json | jq -r '.items[].status.loadBalancer.ingress[].hostname')
com=$(printf "aws elbv2 describe-load-balancers | jq -r '.LoadBalancers[] | select(.DNSName == \"%s\").CanonicalHostedZoneId'" $lbhn)
lbhz=$(eval $com)
echo "$keyz $kchn $lbhz $lbhn"
com2=`printf "aws route53 change-resource-record-sets --hosted-zone-id %s --change-batch '{\"Changes\": [ { \"Action\": \"CREATE\", \"ResourceRecordSet\": { \"Name\": \"%s\", \"Type\": \"A\", \"AliasTarget\":{ \"HostedZoneId\": \"%s\",\"DNSName\": \"%s\", \"EvaluateTargetHealth\": false } } } ]}'" $keyz $kchn $lbhz $lbhn`
echo $com2
eval $com2