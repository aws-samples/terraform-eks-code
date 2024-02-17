# needs LB url in here >
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export WORKSPACE_ID=$(aws grafana list-workspaces --query 'workspaces[0].id' --output text)
#lbdns=$(kubectl get ingress -n keycloak -o json | jq -r '.items[].status.loadBalancer.ingress[].hostname')
domain=keycloak.$ACCOUNT_ID.awsandy.people.aws.dev
export SAML_URL=https://${domain}/realms/keycloak-blog/protocol/saml/descriptor
aws grafana update-workspace-authentication \
    --authentication-providers SAML \
    --workspace-id $WORKSPACE_ID \
    --saml-configuration \
     idpMetadata={url=$SAML_URL},assertionAttributes={role=role},roleValues={admin=admin}
# Patch it where keycloak is deployed
#kubectl patch configmap keycloak-env-vars -n keycloak --type merge --patch '{"data":{"KC_PROXY":"edge"}}'
# Get the pod using configmap and restart the same
kubectl delete pod $(kubectl get pod -n keycloak -o json | jq -r '.items[].metadata.name') -n keycloak

