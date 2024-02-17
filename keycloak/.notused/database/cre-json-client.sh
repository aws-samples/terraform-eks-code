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

cat << EOF > config/keycloak_client.json
{
  "clients": [
    {
      "clientId": "https://${WORKSPACE_ENDPOINT}/saml/metadata",
      "name": "amazon-managed-grafana",
      "enabled": true,
      "protocol": "saml",
      "adminUrl": "https://${WORKSPACE_ENDPOINT}/login/saml",
      "redirectUris": [
        "https://${WORKSPACE_ENDPOINT}/saml/acs"
      ],
      "attributes": {
          "saml.authnstatement": "true",
          "saml.server.signature": "true",
          "saml_name_id_format": "email",
          "saml_force_name_id_format": "true",
          "saml.assertion.signature": "true",
          "saml.client.signature": "false"
      },
      "defaultClientScopes": [],
      "protocolMappers": [
        {
          "name": "name",
          "protocol": "saml",
          "protocolMapper": "saml-user-property-mapper",
          "consentRequired": false,
          "config": {
            "attribute.nameformat": "Unspecified",
            "user.attribute": "firstName",
            "attribute.name": "displayName"
          }
        },
        {
          "name": "email",
          "protocol": "saml",
          "protocolMapper": "saml-user-property-mapper",
          "consentRequired": false,
          "config": {
            "attribute.nameformat": "Unspecified",
            "user.attribute": "email",
            "attribute.name": "mail"
          }
        },
        {
          "name": "role list",
          "protocol": "saml",
          "protocolMapper": "saml-role-list-mapper",
          "config": {
            "single": "true",
            "attribute.nameformat": "Unspecified",
            "attribute.name": "role"
          }
        }
      ]
    }
  ]
}
EOF

