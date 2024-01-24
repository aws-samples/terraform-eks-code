# problem addressing  keycloak.testdomain.local
#
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
#kchn="keycloak.testdomain.local"
kchn=$(echo keycloak.$ACCOUNT_ID.awsandy.people.aws.dev)
export KEYCLOAK_PASSWORD="keycloakpass123"
echo $kchn
com=`printf "docker run \
    -e KEYCLOAK_URL="http://%s:8080/" \
    -e KEYCLOAK_USER="admin" \
    -e KEYCLOAK_PASSWORD="%s" \
    -e IMPORT_FILES_LOCATIONS='/config/*' \
    -v /home/ec2-user/environment/tfekscode/.keycloak/database/config:/config \
    adorsys/keycloak-config-cli:latest" $kchn $KEYCLOAK_PASSWORD`
echo $com