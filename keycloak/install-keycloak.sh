#
echo "Cleaning up if required .."
helm uninstall keycloak -n keycloak &>/dev/null
kubectl delete ns keycloak &>/dev/null
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export HOSTED_ZONE=$ACCOUNT_ID.awsandy.people.aws.dev
export KEYCLOAK_PASSWORD="keycloakpass123"
export WORKSPACE_ENDPOINT=$(aws grafana list-workspaces --query 'workspaces[0].endpoint' --output text)
# validate dns exit of not valid
dnsl=$(dig $ACCOUNT_ID.awsandy.people.aws.dev NS +short | wc -l)
if [[ $dnsl -gt 0 ]]; then
    echo "Setup keycloak certificate"
    # install cert
    terraform init
    terraform apply -auto-approve
    # install keycloak
    sleep 5
    echo "Installing Keycloak"
    envsubst <keycloak_values.yaml.proto >keycloak_values.yaml
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm install keycloak bitnami/keycloak \
        --create-namespace \
        --namespace keycloak \
        -f keycloak_values.yaml
    if [[ $? -eq 0 ]]; then
        envsubst <config-payloads/users.json.proto >config-payloads/users.json
        envsubst <config-payloads/client.json.proto >config-payloads/client.json
        echo "waiting for keycloak..."
        kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=keycloak -n keycloak --timeout=60s
        if [[ $? -eq 0 ]]; then
            kubectl port-forward -n keycloak svc/keycloak 8080:80 &>/dev/null &
            pid=$!
            # Default token expires in one minute. May need to extend. very ugly
            KEYCLOAK_TOKEN=$(curl -sS --fail-with-body -X POST -H "Content-Type: application/x-www-form-urlencoded" \
                --data-urlencode "username=admin" \
                --data-urlencode "password=${KEYCLOAK_PASSWORD}" \
                --data-urlencode "grant_type=password" \
                --data-urlencode "client_id=admin-cli" \
                localhost:8080/realms/master/protocol/openid-connect/token | jq -e -r '.access_token')
            curl -sS -H "Content-Type: application/json" -H "Authorization: bearer ${KEYCLOAK_TOKEN}" -X POST --data @config-payloads/realm.json localhost:8080/admin/realms
            curl -sS -H "Content-Type: application/json" -H "Authorization: bearer ${KEYCLOAK_TOKEN}" -X POST --data @config-payloads/users.json localhost:8080/admin/realms/keycloak-blog/users
            curl -sS -H "Content-Type: application/json" -H "Authorization: bearer ${KEYCLOAK_TOKEN}" -X POST --data @config-payloads/client.json localhost:8080/admin/realms/keycloak-blog/clients
            kill $pid
        else
            echo "keycloak not ready?"
            kubectl get pods -n keycloak
        fi
    else
        echo "Helm chart failed to install"
    fi
    echo "Workspace endpoint = $WORKSPACE_ENDPOINT"
# prep config
else
    echo "ERROR: DNS unexpected response - please discuss with workshop host"
fi
