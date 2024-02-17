export ACM_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='keycloak.testdomain.local'].CertificateArn" --include keyTypes=RSA_2048 --output text)
kubectl delete ns keycloak
aws acm delete-certificate --certificate-arn $ACM_ARN