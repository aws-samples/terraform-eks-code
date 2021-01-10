cat 2048_ingress.yml |  sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' | kubectl delete -f -
