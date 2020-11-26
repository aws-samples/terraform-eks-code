kubectl create deployment nginx --image=566972129213.dkr.ecr.eu-west-1.amazonaws.com/nginx
kubectl scale --replicas=3 deployments/nginx
kubectl expose deployment/nginx --type=NodePort --port 80
kubectl get pods -o wide
echo "kubectl run -i --rm --tty debug --image=566972129213.dkr.ecr.eu-west-1.amazonaws.com/busybox -- sh"
echo "wget google.com -O -"
echo "wget nginx -O -"