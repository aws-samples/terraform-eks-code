kubectl delete -f samples/addons
kubectl delete -f samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
terraform destroy -auto-approve