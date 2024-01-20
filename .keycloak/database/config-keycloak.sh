kchn="keycloak.testdomain.local"
export KEYCLOAK_PASSWORD="keycloakpass123"
com=`printf "docker run \
    -e KEYCLOAK_URL="http://%s:8080/" \
    -e KEYCLOAK_USER="admin" \
    -e KEYCLOAK_PASSWORD="%s" \
    -e KEYCLOAK_AVAILABILITYCHECK_ENABLED=true \
    -e KEYCLOAK_AVAILABILITYCHECK_TIMEOUT=120s \
    -e IMPORT_FILES_LOCATIONS='/config/*' \
    -v config:/config \
    adorsys/keycloak-config-cli:latest" $kchn $KEYCLOAK_PASSWORD`