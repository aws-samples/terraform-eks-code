

Debug:
Check for annotation on all nodes  (use reannotate script if needed)

kubectl get nodes -o json | jq .items[].metadata.annotations


kubectl describe pods  coredns-6987776bbd-c9q4z -n kube-system

kubectl rollout restart deployment deployment-2048 -n game-2048
kubectl rollout restart deployment coredns -n kube-system


kubectl get nodes 
kubectl get nodes --show-labels
kubectl get node --selector='eks.amazonaws.com/nodegroup==ng2-mycluster1


Debug application:

kubectl port-forward service/service-2048 8080:80 -n game-2048

(preview running app in Code9  - curl localhost:8080)


Debug Ingress

In a terminal follow the logs:
kubectl logs -f aws-load-balancer-controller-6768894cc9-rsjk2 -n kube-system 

kubectl describe ingress.extensions/ingress-2048 -n game-2048


```

Name:             ingress-2048
Namespace:        game-2048
Address:          
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /*   service-2048:80 (100.64.119.96:80,100.64.130.37:80)
Annotations:  alb.ingress.kubernetes.io/scheme: internal
              alb.ingress.kubernetes.io/target-type: ip
              kubernetes.io/ingress.class: alb
Events:
  Type     Reason             Age   From     Message
  ----     ------             ----  ----     -------
  Warning  FailedDeployModel  14m   ingress  Failed deploy model due to ListenerNotFound: One or more listeners not found
           status code: 400, request id: 7890f626-027c-4ebd-b7f0-289886174d28
  Warning  FailedDeployModel  106s  ingress  Failed deploy model due to RequestError: send request failed
caused by: Post "https://wafv2.eu-west-1.amazonaws.com/": dial tcp 52.95.119.96:443: i/o timeout

```


Go and manually fixup the Listener 
delete fixed 404 response
Add 




---

terminate a node

kubectl rollout restart deployment deployment-2048 -n game-2048
kubectl rollout restart deployment coredns -n kube-system


