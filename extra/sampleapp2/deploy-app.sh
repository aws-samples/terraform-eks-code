kubectl apply -f 2048_namespace.yml
cat 2048_deployment-ng1.yml | ./subvar.sh | kubectl apply -f -
cat 2048_deployment-ng2.yml | ./subvar.sh | kubectl apply -f -
kubectl apply -f 2048_service.yml
kubectl apply -f 2048_ingress.yml 
