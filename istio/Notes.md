https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports

Gateway type:
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.0.0" | kubectl apply -f -; }





Ingress type

kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml





helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
helm show values istio/gateway


