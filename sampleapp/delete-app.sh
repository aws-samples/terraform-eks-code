set +e
echo "Deleting an Ingress takes a few minutes......"
cat 2048_ingress.yml |  sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' | kubectl delete -f -
kubectl delete -f 2048_service.yml
kubectl delete -f 2048_deployment.yml
kubectl delete -f 2048_namespace.yml
set -e