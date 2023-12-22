export CURRET_PET=keycloak
export ACM_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='keycloack.local'].CertificateArn" --include keyTypes=RSA_4096 --output text)
envsubst < "manifest-template.yaml" > "keycloak.yaml"
#export CURRET_PET=rabbit
#export ACM_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='rabbit.local'].CertificateArn" --include keyTypes=RSA_4096 --output text)
#envsubst < "manifest-template.yaml" > "rabbit.yaml"
#export CURRET_PET=chipmunk
#export ACM_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='chipmunk.local'].CertificateArn" --include keyTypes=RSA_4096 --output text)
#envsubst < "manifest-template.yaml" > "chipmunk.yaml"
#export CURRET_PET=hamster
#export ACM_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='hamster.local'].CertificateArn" --include keyTypes=RSA_4096 --output text)
#envsubst < "manifest-template.yaml" > "hamster.yaml"
kubectl create ns myapplications-ns
#kubectl apply -f ./hamster.yaml 
#kubectl apply -f ./chipmunk.yaml 
#kubectl apply -f ./rabbit.yaml
kubectl apply -f ./keycloack.yaml
