export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export HOSTED_ZONE=$ACCOUNT_ID.awsandy.people.aws.dev
export WORKSPACE_ID=$(aws grafana list-workspaces --query 'workspaces[0].id' --output text)
export SAML_URL=https://keycloak.$HOSTED_ZONE/realms/keycloak-blog/protocol/saml/descriptor
aws grafana update-workspace-authentication \
    --authentication-providers SAML \
    --workspace-id $WORKSPACE_ID \
    --saml-configuration \
     idpMetadata={url=$SAML_URL},assertionAttributes={role=role},roleValues={admin=admin}