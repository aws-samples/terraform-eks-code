echo "Installing Keycloak"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install keycloak bitnami/keycloak \
    --create-namespace \
    --namespace keycloak \
    --version 16.1.7 \
    -f keycloak_values.yaml
    
if [[ $? -ne 0 ]]; then
    echo "Error helm installing Keycloak"
    exit
fi
