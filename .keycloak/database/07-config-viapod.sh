jsonconfig=$(cat config/keycloak_config.json)
com=$(printf "kubectl -n keycloak exec -it $(kubectl get pod -n keycloak -o json | jq -r '.items[].metadata.name') -- /bin/bash -c \"cd /opt/keycloak/bin/ && 
> ./kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password keycloakpass123 && ./kcadm.sh create realms -f - << EOF
{ \"realm\": \"demorealm\", \"enabled\": true }
EOF && exit\"")
echo $com