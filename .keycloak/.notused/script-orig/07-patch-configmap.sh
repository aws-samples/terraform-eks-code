# Patch it where keycloak is deployed
kubectl patch configmap keycloak-env-vars -n keycloak --type merge --patch '{"data":{"KC_PROXY":"edge"}}'
# Get the pod using configmap and restart the same
kubectl delete pod keycloak-0 -n keycloak