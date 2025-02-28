#keycloak.191146365370.awsandy.people.aws.dev
ADMIN_PASSWORD=$(kubectl get secret -n keycloak keycloak -o json | jq -r '.data[]' | base64 -d)
kubectl port-forward -n keycloak svc/keycloak 8080:80 > /dev/null 2>&1 &
pid=$!
export ADMIN_PASSWORD=keycloakpass123
KEYCLOAK_TOKEN=$(curl -sS  --fail-with-body -X POST -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "username=admin" \
  --data-urlencode "password=${ADMIN_PASSWORD}" \
  --data-urlencode "grant_type=password" \
  --data-urlencode "client_id=admin-cli" \
  localhost:8080/realms/master/protocol/openid-connect/token | jq -e -r '.access_token')
echo "creating realm"
curl -sS -H "Content-Type: application/json" \
  -H "Authorization: bearer ${KEYCLOAK_TOKEN}" \
  -X POST --data @config-payloads/realm-payload.json \
  localhost:8080/admin/realms
echo "creating user"
curl -sS -H "Content-Type: application/json" \
  -H "Authorization: bearer ${KEYCLOAK_TOKEN}" \
  -X POST --data @config-payloads/users.json \
  localhost:8080/admin/realms/keycloak-blog/users
curl -sS -H "Content-Type: application/json" \
  -H "Authorization: bearer ${KEYCLOAK_TOKEN}" \
  -X POST --data @config-payloads/client.json \
  localhost:8080/admin/realms/keycloak-blog/clients
