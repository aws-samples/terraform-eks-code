

reset-environment
put the standard app back in



prepare-environment introduction/getting-started
(does not uninstall standard app)



EKS runtime monitoring hold daemonset 
- may not have enough resources
- will also hold open karpenter nodes


pods on node
kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=ip-100-65-56-96.eu-west-1.compute.internal
drain a node:
kubectl drain --ignore-daemonsets ip-100-65-56-96.eu-west-1.compute.internal --delete-emptydir-data
Karpenter should then mop up ?