# problem addressing  keycloak.testdomain.local
#
#kubectl port-forward service/keycloak 8080:8080 -n keycloak
export KEYCLOAK_PASSWORD="keycloakpass123"
echo $kchn
com=`printf "docker run \
    -e KEYCLOAK_URL="http://localhost:8080/" \
    -e KEYCLOAK_USER="admin" \
    -e KEYCLOAK_PASSWORD="%s" \
    -e IMPORT_FILES_LOCATIONS='/config/*' \
    -v /home/ec2-user/environment/tfekscode/.keycloak/database/config:/config \
    adorsys/keycloak-config-cli:latest" $kchn $KEYCLOAK_PASSWORD`
echo $com