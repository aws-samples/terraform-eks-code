# create dedicated namespace for our deployments
kubectl create ns hotel
# create TLS cert
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout auth-tls.key -out auth-tls.crt -subj "/CN=keycloak.testdomain.local/O=hotel"
kubectl create secret -n hotel tls auth-tls-secret --key auth-tls.key --cert auth-tls.crt
# deploy PostgreSQL cluster - in dev we will use 1 replica, in production use the default value of 3 (or set it to even a higher value)
helm install -n hotel keycloak-db bitnami/postgresql-ha --set postgresql.replicaCount=1
# deploy Keycloak cluster
# envsubst replaces all env variables placeholders with their actual values
envsubst < keycloak-eks-placeholder.yaml > keycloak-eks.yaml
kubectl apply -n hotel -f keycloak-eks.yaml
# deploy AWS ALB ingress
# envsubst replaces all env variables placeholders with their actual values
envsubst < keycloak-ingress-eks-placeholder.yaml > keycloak-ingress-eks.yaml
# deploy the ingress
kubectl apply -n hotel -f keycloak-ingress-eks.yaml