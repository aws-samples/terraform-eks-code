#
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export HOSTED_ZONE=$ACCOUNT_ID.awsandy.people.aws.dev
export KEYCLOAK_PASSWORD="keycloakpass123"
export WORKSPACE_ENDPOINT=$(aws grafana list-workspaces --query 'workspaces[0].endpoint' --output text)
# validate dns exit of not valid
acc=$(aws sts get-caller-identity --query Account --output text)
dnsl=$(dig $acc.awsandy.people.aws.dev NS +short | wc -l)
if [[ $dnsl -gt 0 ]]; then
echo "terrafor cert"
# install cert
    terraform init
    terraform apply -auto-approve
# install keycloak
sleep 5
echo "Installing Keycloak"
envsubst < keycloak_values.yaml.proto > keycloak_values.yaml
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install keycloak bitnami/keycloak \
    --create-namespace \
    --namespace keycloak \
    -f keycloak_values.yaml
echo $?
if [[ $? -eq 0 ]];then


else
    echo "Helm chart failed to install"
fi

# prep config

fi
