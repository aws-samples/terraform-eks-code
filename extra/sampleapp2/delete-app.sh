cat 2048_ingress1.yml |  sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' | kubectl delete -f -
cat 2048_ingress2.yml |  sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' | kubectl delete -f -
kubectl delete -f 2048_service1.yml
kubectl delete -f 2048_service2.yml
kubectl delete -f 2048_deployment-ng1.yml
kubectl delete -f 2048_deployment-ng2.yml
#kubectl delete -f 2048_namespace1.yml
#kubectl delete -f 2048_namespace2.yml