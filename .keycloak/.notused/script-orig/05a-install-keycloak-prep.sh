export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export HOSTED_ZONE=$ACCOUNT_ID.awsandy.people.aws.dev
export KEYCLOAK_PASSWORD="keycloakpass123"
export WORKSPACE_ENDPOINT=$(aws grafana list-workspaces --query 'workspaces[0].endpoint' --output text)
echo $WORKSPACE_ENDPOINT
echo $KEYCLOAK_PASSWORD
cat << EOF > keycloak_values.yaml
auth:
  adminUser: admin
  adminPassword: $KEYCLOAK_PASSWORD
keycloakConfigCli:
  enabled: false
  configuration:
    realm.json: |
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
        ],
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
service:
  type: ClusterIP
ingress:
  enabled: true
  ingressClassName: alb
  pathType: Prefix
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: 'ip'
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
  hostname: keycloak.${HOSTED_ZONE}
EOF
cat keycloak_values.yaml
#echo "Installing Keycloak"
#helm repo add bitnami https://charts.bitnami.com/bitnami
#helm install keycloak bitnami/keycloak \
#    --create-namespace \
#    --namespace keycloak \
#    -f keycloak_values.yaml
#echo $KEYCLOAK_PASSWORD
