kubectl apply -f 2048-namespace.yml
cat 2048-deployment.yml | ./subvar.sh | kubectl apply -f -
kubectl apply -f 2048-service.yml
kubectl apply -f 2048_ingress.yml 
