echo "Cleaning up if required .."
helm uninstall keycloak -n keycloak &>/dev/null
kubectl delete ns keycloak &>/dev/null
terraform init -upgrade
terraform destroy -auto-approve