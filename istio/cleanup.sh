cd ~/environment/istio-1.20.3
kubectl delete -f samples/addons
kubectl delete -f samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
cd ~/environment/tfekscode/istio
terraform destroy -auto-approve