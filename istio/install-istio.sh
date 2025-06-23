#cd ~/environment
#curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.24.3 TARGET_ARCH=x86_64 sh -
## https://istio.io/latest/docs/setup/getting-started/
cd ~/environment/istio-1.24.3
kubectl create ns sample 
kubectl label namespace sample istio-injection=enabled
kubectl -n sample apply -f samples/bookinfo/platform/kube/bookinfo.yaml

echo "looking for 5 services"
kubectl get services
echo "looking for 2/2 so each with a sidecar"
kubectl get pods

#kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml