### Troubleshoot

helm search repo eks/aws-load-balancer-controller -l

```
helm delete aws-load-balancer-controller -n kube-system
```


```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=mycluster1 --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
NAME: aws-load-balancer-controller
LAST DEPLOYED: Tue Nov 24 19:03:22 2020
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
AWS Load Balancer controller installed!
```

Appear to be ok but:
```
kubectl get pods -A
NAMESPACE     NAME                                            READY   STATUS            RESTARTS   AGE
kube-system   aws-load-balancer-controller-7466bd5fcb-v8ngn   0/1     ImagePullBackOff  0  4m22s
```


kubectl describe deployment -n kube-system aws-load-balancer-controller
```
...
  Containers:
   aws-load-balancer-controller:
    Image:       602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-load-balancer-controller:v2.0.1
    Ports:       9443/TCP, 8080/TCP
    Host Ports:  0/TCP, 0/TCP
...
```

notice the us-west-2 - we are in eu-west-1
& need:

602401143452.dkr.ecr.eu-west-1.amazonaws.com

```
helm delete aws-load-balancer-controller -n kube-system
```

Override image location  (the IAM service controller shoud not be installed
eksctl delete iamserviceaccount --cluster mycluster1 --namespace=kube-system --name=aws-load-balancer-controller

```

helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=mycluster1 --set image.repository=602401143452.dkr.ecr.eu-west-1.amazonaws.com/amazon/aws-load-balancer-controller 
```