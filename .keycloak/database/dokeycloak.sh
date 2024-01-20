domain=testdomain.local
vpcid=$(aws ssm get-parameter --name /workshop/tf-eks/eks-vpc --query Parameter.Value --output text)
export DB_HOSTNAME=$(aws ssm get-parameter --name /workshop/tf-eks/db_hostname --query Parameter.Value --output text)
keyz=$(aws route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name=="testdomain.local.").Id' | cut -f3 -d'/')
export ACM_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='keycloak.testdomain.local'].CertificateArn" --include keyTypes=RSA_2048 --output text)
if [[ $ACM_ARN == *"acm"* ]];then
    aws acm delete-certificate --certificate-arn $ACM_ARN
else
    echo "No existing cert to delete"
fi
#aws route53 create-hosted-zone --name $domain \
#--caller-reference my-keycloak-zone5 \
#--hosted-zone-config Comment="testdomain local",PrivateZone=true --vpc VPCRegion=eu-west-1,VPCId=$vpcid
#if [[ $? -ne 0 ]];then
#  echo "phz failure exiting ..."
#  exit
#fi
#keyz=$(aws route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name=="testdomain.local.").Id' | cut -f3 -d'/')
openssl req -new -x509 -sha256 -nodes -newkey rsa:2048 -keyout private_keycloak.key -out certificate_keycloak.crt -subj "/CN=keycloak.testdomain.local"
aws acm import-certificate --certificate fileb://certificate_keycloak.crt --private-key fileb://private_keycloak.key
sleep 2
export ACM_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='keycloak.testdomain.local'].CertificateArn" --include keyTypes=RSA_2048 --output text)
export HOSTED_ZONE=testdomain.local
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
#export HOSTED_ZONE=$ACCOUNT_ID.awsandy.people.aws.dev
export KEYCLOAK_PASSWORD="keycloakpass123"
export WORKSPACE_ENDPOINT=$(aws grafana list-workspaces --query 'workspaces[0].endpoint' --output text)
echo $WORKSPACE_ENDPOINT
echo $KEYCLOAK_PASSWORD
export WORKSPACE_ID=$(aws grafana list-workspaces --query 'workspaces[0].id' --output text)
envsubst < manifest/keycloak.yaml > keycloak.yaml