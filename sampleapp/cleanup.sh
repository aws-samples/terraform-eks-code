userid=$(aws iam list-service-specific-credentials --user-name git-user | jq -r .ServiceSpecificCredentials[0].ServiceSpecificCredentialId)
if [ "$userid" != "null" ]; then
aws iam delete-service-specific-credential --service-specific-credential-id $userid --user-name git-user
fi