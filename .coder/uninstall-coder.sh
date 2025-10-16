helm uninstall --namespace coder coder
kubectl delete secret generic coder-db-url -n coder
helm uninstall --namespace coder postgresql
kubectl delete namespace coder