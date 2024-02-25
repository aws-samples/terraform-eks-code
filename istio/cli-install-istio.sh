cd ~/environment
rm -rf istio-1.20.3
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.20.3 TARGET_ARCH=x86_64 sh -
cd ~/environment/istio-1.20.3
export PATH=$PWD/bin:$PATH
istioctl version --remote=false
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
sleep 5
kubectl get services
echo "wait 30s for pods"
sleep 30
kubectl get pods
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
istioctl analyze

export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') 
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
echo $INGRESS_HOST $INGRESS_PORT $SECURE_INGRESS_PORT
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

echo "http://$GATEWAY_URL/productpage"
for i in $(seq 1 100); do curl -s -o /dev/null "http://$GATEWAY_URL/productpage"; done



kubectl apply -f samples/addons
kubectl rollout status deployment/kiali -n istio-system
