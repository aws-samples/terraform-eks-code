setups/uninstall.sh
kubectl delete ns argo-cd
kubectl delete ns crossplane-system
kubectl delete ns cert-manager
kubectl delete ns external-dns
kubectl delete ns external-secrets
kubectl delete ns ingress-nginx  
kubectl delete ns aws-load-balancer-controller


