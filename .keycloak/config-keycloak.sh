echo "start port forwarding for local config"
com="kubectl port-forward -n keycloak svc/keycloak 8080:80"
eval $com &
sleep 5
ps -ef | grep port-forward | grep -v grep
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
pid=$(ps -ef | grep port-forward | grep -v grep | awk '{print $2}')
kill $pid
