https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports

Gateway type:
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.0.0" | kubectl apply -f -; }





Ingress type

kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml





helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
helm show values istio/gateway




-------


https://aws.amazon.com/blogs/mt/monitoring-and-visualizing-amazon-eks-signals-with-kiali-and-aws-managed-open-source-services/

cd ~/environment/istio-1.20.3
kubectl apply -f samples/addons
kubectl port-forward -n istio-system svc/$ks 8080:20001 --address 0.0.0.0


kubectl describe cm kiali -n istio-system | grep url
kubectl delete -f samples/addons


http://$cloud9IP:20001/kiali

external c9:
https://docs.aws.amazon.com/cloud9/latest/user-guide/app-preview.html#app-preview-preview-app


open 8080 on SG
get ec2 dns name & use port 8080
http://ec2-3-252-213-117.eu-west-1.compute.amazonaws.com:8080





Step 4: Generate traffic to collect telemetry data (optional)

To view the view telemetry data, you need to generate the traffic by accessing the application multiple times, open a new terminal tab and use these commands to send a traffic to the mesh:

export GATEWAY_URL=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

watch --interval 1 curl -s -I -XGET "http://${GATEWAY_URL}/productpage"






