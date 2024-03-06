# check app it in clone - copy files push
test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || "echo AWS_REGION is not set && exit"
#aws iam attach-user-policy --user-name git-user --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitPowerUser
#aws iam create-service-specific-credential --user-name git-user --service-name codecommit.amazonaws.com | tee /tmp/gituser_output.json
usercred=$(aws iam create-service-specific-credential --user-name git-user --service-name codecommit.amazonaws.com)
GIT_USERNAME=$(echo $usercred | jq -r '.ServiceSpecificCredential.ServiceUserName')
GIT_PASSWORD=$(echo $usercred | jq -r '.ServiceSpecificCredential.ServicePassword')
CREDENTIAL_ID=$(echo $usercred | jq -r '.ServiceSpecificCredential.ServiceSpecificCredentialId')
test -n "$GIT_USERNAME" && echo GIT_USERNAME is "$GIT_USERNAME" || "echo GIT_USERNAME is not set && exit"
git clone codecommit::$AWS_REGION://eksworkshop-app