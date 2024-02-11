#
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export HOSTED_ZONE=$ACCOUNT_ID.awsandy.people.aws.dev
export KEYCLOAK_PASSWORD="keycloakpass123"
export WORKSPACE_ENDPOINT=$(aws grafana list-workspaces --query 'workspaces[0].endpoint' --output text)
# validate dns exit of not valid
acc=$(aws sts get-caller-identity --query Account --output text)
dnsl=$(dig $acc.awsandy.people.aws.dev NS +short | wc -l)
if [[ $dnsl -gt 0 ]]; then
echo "terrafor cert"
# install cert
    terraform init
    terraform apply -auto-approve
# install keycloak
sleep 5
echo "Installing Keycloak"
envsubst < keycloak_values.yaml.proto > keycloak_values.yaml
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install keycloak bitnami/keycloak \
    --create-namespace \
    --namespace keycloak \
    -f keycloak_values.yaml
echo $?
if [[ $? -eq 0 ]];then
    envsubst < config-payloads/users.json.proto > config-payloads/users.json
    envsubst < config-payloads/client.json.proto > config-payloads/client.json
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=keycloak -n keycloak  --timeout=30s
    kubectl port-forward -n keycloak svc/keycloak 8080:80 > /dev/null 2>&1 &
    pid=$!
    # Default token expires in one minute. May need to extend. very ugly
    KEYCLOAK_TOKEN=$(curl -sS  --fail-with-body -X POST -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "username=cnoe-admin" \
    --data-urlencode "password=${ADMIN_PASSWORD}" \
    --data-urlencode "grant_type=password" \
    --data-urlencode "client_id=admin-cli" \
    localhost:8080/realms/master/protocol/openid-connect/token | jq -e -r '.access_token')

    curl -sS -H "Content-Type: application/json"   -H "Authorization: bearer ${KEYCLOAK_TOKEN}"   -X POST --data @config-payloads/realm.json   localhost:8080/admin/realms
    curl -sS -H "Content-Type: application/json"   -H "Authorization: bearer ${KEYCLOAK_TOKEN}"   -X POST --data @config-payloads/users.json   localhost:8080/admin/realms/keycloak-blog/users
    curl -sS -H "Content-Type: application/json"   -H "Authorization: bearer ${KEYCLOAK_TOKEN}"   -X POST --data @config-payloads/client.json   localhost:8080/admin/realms/keycloak-blog/clients
    kill $pid
else
    echo "Helm chart failed to install"
fi

# prep config

fi
