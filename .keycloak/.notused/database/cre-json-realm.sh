export HOSTED_ZONE=testdomain.local
#export HOSTED_ZONE=$ACCOUNT_ID.awsandy.people.aws.dev
export KEYCLOAK_PASSWORD="keycloakpass123"
export WORKSPACE_ENDPOINT=$(aws grafana list-workspaces --query 'workspaces[0].endpoint' --output text)
echo $WORKSPACE_ENDPOINT
echo $KEYCLOAK_PASSWORD
export WORKSPACE_ID=$(aws grafana list-workspaces --query 'workspaces[0].id' --output text)
#export SAML_URL=https://keycloak.local/realms/keycloak-blog/protocol/saml/descriptor
echo "Grafana endpoint=$WORKSPACE_ENDPOINT"
echo $KEYCLOAK_PASSWORD

cat << EOF > config/keycloak_realm.json
{
  "realm": "keycloak-blog",
  "enabled": true,
  "roles": {
    "realm": [
      {
        "name": "admin"
      }
    ]
  },
  "users": [
    {
      "username": "admin",
      "email": "admin@keycloak",
      "enabled": true,
      "firstName": "Admin",
      "realmRoles": [
        "admin"
      ],
      "credentials": [
        {
          "type": "password",
          "value": "${KEYCLOAK_PASSWORD}"
        }
      ]
    }
  ]
}
EOF
