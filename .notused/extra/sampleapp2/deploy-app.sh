kubectl apply -f 2048_namespace1.yml
kubectl apply -f 2048_namespace2.yml
cat 2048_deployment-ng1.yml | ./subvar.sh | kubectl apply -f -
cat 2048_deployment-ng2.yml | ./subvar.sh | kubectl apply -f -
kubectl apply -f 2048_service1.yml
kubectl apply -f 2048_service2.yml
 
