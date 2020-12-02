# check app it in clone - copy files push
test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || "echo AWS_REGION is not set && exit"
#aws iam attach-user-policy --user-name git-user --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitPowerUser
aws iam create-service-specific-credential --user-name git-user --service-name codecommit.amazonaws.com | tee /tmp/gituser_output.json
GIT_USERNAME=$(cat /tmp/gituser_output.json | jq -r '.ServiceSpecificCredential.ServiceUserName')
GIT_PASSWORD=$(cat /tmp/gituser_output.json | jq -r '.ServiceSpecificCredential.ServicePassword')
CREDENTIAL_ID=$(cat /tmp/gituser_output.json | jq -r '.ServiceSpecificCredential.ServiceSpecificCredentialId')
test -n "$GIT_USERNAME" && echo GIT_USERNAME is "$GIT_USERNAME" || "echo GIT_USERNAME is not set && exit"git clone codecommit::$AWS_REGION://eksworkshop-app


