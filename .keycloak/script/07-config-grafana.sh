# needs LB url in here >
lbdns=$(kubectl get ingress -n keycloak -o json | jq -r '.items[].status.loadBalancer.ingress[].hostname')
export SAML_URL=https://${lbdns}/realms/keycloak-blog/protocol/saml/descriptor
aws grafana update-workspace-authentication \
    --authentication-providers SAML \
    --workspace-id $WORKSPACE_ID \
    --saml-configuration \
     idpMetadata={url=$SAML_URL},assertionAttributes={role=role},roleValues={admin=admin}
# Patch it where keycloak is deployed
kubectl patch configmap keycloak-env-vars -n keycloak --type merge --patch '{"data":{"KC_PROXY":"edge"}}'
# Get the pod using configmap and restart the same
kubectl delete pod keycloak-0 -n keycloak

