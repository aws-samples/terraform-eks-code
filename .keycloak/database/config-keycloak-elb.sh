lbhn=$(kubectl -n keycloak get ingress -o json | jq -r '.items[].status.loadBalancer.ingress[].hostname')
export KEYCLOAK_PASSWORD="keycloakpass123"
com=`printf "docker run \
    -e KEYCLOAK_URL="http://%s:8080/" \
    -e KEYCLOAK_USER="admin" \
    -e KEYCLOAK_PASSWORD="%s" \
    -e IMPORT_FILES_LOCATIONS='/config/*' \
    -v /home/ec2-user/environment/tfekscode/.keycloak/database/config:/config \
    adorsys/keycloak-config-cli:latest" $lbhn $KEYCLOAK_PASSWORD`
echo $com