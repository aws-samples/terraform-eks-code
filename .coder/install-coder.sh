kubectl create namespace coder
# Install PostgreSQL
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add coder-v2 https://helm.coder.com/v2
helm install postgresql bitnami/postgresql \
    --namespace coder \
    --set image.repository=bitnamilegacy/postgresql \
    --set auth.username=coder \
    --set auth.password=coder \
    --set auth.database=coder \
    --set primary.persistence.size=10Gi
kubectl create secret generic coder-db-url -n coder \
  --from-literal=url="postgres://coder:coder@postgresql.coder.svc.cluster.local:5432/coder?sslmode=disable"
helm install coder coder-v2/coder \
    --namespace coder \
    --values values.yaml \
    --version 2.27.0