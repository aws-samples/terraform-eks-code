cat keycloak_values.yaml
echo "Installing Keycloak"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install keycloak bitnami/keycloak \
    --create-namespace \
    --namespace keycloak \
    -f keycloak_values.yaml
echo $?

