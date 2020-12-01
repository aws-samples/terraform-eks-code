cat 2048_ingress.yml |  sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' | kubectl delete -f -
kubectl delete -f 2048-service.yml
kubectl delete -f 2048-deployment.yml
kubectl delete -f 2048-namespace.yml