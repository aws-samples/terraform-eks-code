openssl req -new -x509 -sha256 -nodes -newkey rsa:4096 -keyout private_keycloak.key -out certificate_keycloak.crt -subj "/CN=keycloak.local"
aws acm import-certificate --certificate fileb://certificate_keycloak.crt --private-key fileb://private_keycloak.key
vpcid=$(aws ssm get-parameter --name /workshop/tf-eks/eks-vpc --query Parameter.Value --output text)
aws route53 create-hosted-zone --name keycloak.local \
--caller-reference my-keycloak-zone \
--hosted-zone-config Comment="keycloak local",PrivateZone=true --vpc VPCRegion=eu-west-1,VPCId=$vpcid
keyz=$(aws route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name=="keycloak.local.").Id' | cut -f3 -d'/')
export ACM_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='keycloak.local'].CertificateArn" --include keyTypes=RSA_4096 --output text)
export HOSTED_ZONE=keycloak.local
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
#export HOSTED_ZONE=$ACCOUNT_ID.awsandy.people.aws.dev
export KEYCLOAK_PASSWORD="keycloakpass123"
export WORKSPACE_ENDPOINT=$(aws grafana list-workspaces --query 'workspaces[0].endpoint' --output text)
echo $WORKSPACE_ENDPOINT
echo $KEYCLOAK_PASSWORD
export WORKSPACE_ID=$(aws grafana list-workspaces --query 'workspaces[0].id' --output text)
export SAML_URL=https://keycloak.local/realms/keycloak-blog/protocol/saml/descriptor
cat << EOF > keycloak_values.yaml
auth:
  adminUser: admin
  adminPassword: $KEYCLOAK_PASSWORD
keycloakConfigCli:
  enabled: true
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
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/certificate-arn: ${ACM_ARN}
  hostname: keycloak.local
EOF

