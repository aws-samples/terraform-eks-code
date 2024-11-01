cp ingress.yaml ~/environment/eks-workshop/modules/exposing/ingress/creating-ingress
cd ~/environment/eks-workshop/base-application/catalog
kubectl apply -k ~/environment/eks-workshop/base-application/catalog
kubectl wait --for=condition=Ready pods --all -n catalog --timeout=180s
kubectl apply -k ~/environment/eks-workshop/base-application
kubectl wait --for=condition=Ready --timeout=180s pods -l app.kubernetes.io/created-by=eks-workshop -A
kubectl get deployment -l app.kubernetes.io/created-by=eks-workshop -A

