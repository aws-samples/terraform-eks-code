#cat 2048_ingress.yml |  sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' | kubectl delete -f -
kubectl delete -f 2048_service.yml
kubectl delete -f 2048_deployment.yml
kubectl delete -f 2048_namespace.yml
userid=$(aws iam list-service-specific-credentials --user-name git-user | jq -r .ServiceSpecificCredentials[0].ServiceSpecificCredentialId )
aws iam delete-service-specific-credential --service-specific-credential-id $userid