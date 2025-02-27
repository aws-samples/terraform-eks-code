#kubectl apply -f https://raw.githubusercontent.com/aws-containers/retail-store-sample-app/main/dist/kubernetes/deploy.yaml
#kubectl wait --for=condition=available deployments --all
#sleep 5
#kubectl get svc ui
kubectl apply -f sampleapp.yaml -n sampleapp
kubectl wait --for=condition=available deployments --all -n sampleapp
sleep 5
kubectl get svc ui -n sampleapp
 