### Troubleshoot

Slow ingress deletion:
https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/1879
https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/v2.4.2/docs/deploy/upgrade/migrate_v1_v2.md#backwards-compatibility

 * You'll need to manually add `elbv2.k8s.aws/targetGroupBinding=shared` description to that inbound rule so that AWSLoadBalancerController can delete such rule when you delete your Ingress.
     * The following shell pipeline can be used to update the rules automatically. Replace `$REGION` and `$SG_ID` with your own values. After running it change `DryRun: true` to `DryRun: false` to have it actually update your security group:
       ```
       aws --region $REGION ec2 update-security-group-rule-descriptions-ingress --cli-input-json "$(aws --region $REGION ec2 describe-security-groups --group-ids $SG_ID | jq '.SecurityGroups[0] | {DryRun: true, GroupId: .GroupId ,IpPermissions: (.IpPermissions | map(select(.FromPort==0 and .ToPort==65535) | .UserIdGroupPairs |= map(.Description="elbv2.k8s.aws/targetGroupBinding=shared"))) }' -M)"


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




```bash
kubectl describe pods aws-load-balancer-controller-67bc87c6bf-xpqfv -n kube-system
```
```
cda77aab0b5561b48987226d3b1c851fa611924a5045ac3614f87" network for pod "aws-load-balancer-controller-67bc87c6bf-xpqfv": networkPlugin cni failed to set up pod "aws-load-balancer-controller-67bc87c6bf-xpqfv_kube-system" network: add cmd: failed to assign an IP address to container
  Warning  FailedCreatePodSandBox  11m                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "ed7de0aeb264caf8badd6bb83cb974bd0fb26ef324f5a4ed416fc7baea6d9197" network for pod "aws-load-balancer-controller-67bc87c6bf-xpqfv": networkPlugin cni failed to set up pod "aws-load-balancer-controller-67bc87c6bf-xpqfv_kube-system" network: add cmd: failed to assign an IP address to container
  Normal   SandboxChanged          10m (x12 over 11m)   kubelet            Pod sandbox changed, it will be killed and re-created.
  Warning  FailedCreatePodSandBox  68s (x449 over 10m)  kubelet            (combined from similar events): Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "46c4cf2d0757a00d748537b560327932a833b3c92ea1d5d805c3de0204308dfa" network for pod "aws-load-balancer-controller-67bc87c6bf-xpqfv": networkPlugin cni failed to set up pod "aws-load-balancer-controller-67bc87c6bf-xpqfv_kube-system" network: add cmd: failed to assign an IP address to container
```

Reannotate nodes

