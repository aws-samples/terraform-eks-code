cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      terminationGracePeriodSeconds: 0
      containers:
        - name: inflate
          image: $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aws/eks-distro/kubernetes/pause:3.5
          resources:
            requests:
              cpu: 1
EOF
kubectl scale deployment inflate --replicas 5
for i in `kubectl get pods -n karpenter -l karpenter=controller -o name`; do
kubectl logs -n karpenter $i
done
#kubectl logs -f -n karpenter $(kubectl get pods -n karpenter -l karpenter=controller -o name | head -1)