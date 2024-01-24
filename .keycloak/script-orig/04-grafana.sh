RESULT=$(aws grafana create-workspace \
    --account-access-type="CURRENT_ACCOUNT" \
    --authentication-providers "SAML" \
    --permission-type "CUSTOMER_MANAGED" \
    --workspace-name "keycloak-blog" \
    --workspace-role-arn "keycloak-blog-grafana-role")

export WORKSPACE_ID=$(jq -r .workspace.id <<< $RESULT)

while true; do
    STATUS=$(aws grafana describe-workspace --workspace-id $WORKSPACE_ID | jq -r .workspace.status)
    if [[ "${STATUS}" == "ACTIVE" ]]; then break; fi
    sleep 1
    echo -n '.'
done

export WORKSPACE_ENDPOINT=$(aws grafana describe-workspace --workspace-id $WORKSPACE_ID | jq -r .workspace.endpoint)