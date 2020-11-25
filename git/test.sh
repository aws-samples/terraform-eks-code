#aws codecommit create-repository --repository-name eksworkshop-app
#aws iam create-user --user-name git-user
aws iam attach-user-policy --user-name git-user --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitPowerUser
aws iam create-service-specific-credential --user-name git-user --service-name codecommit.amazonaws.com | tee /tmp/gituser_output.json

GIT_USERNAME=$(cat /tmp/gituser_output.json | jq -r '.ServiceSpecificCredential.ServiceUserName')
GIT_PASSWORD=$(cat /tmp/gituser_output.json | jq -r '.ServiceSpecificCredential.ServicePassword')
CREDENTIAL_ID=$(cat /tmp/gituser_output.json | jq -r '.ServiceSpecificCredential.ServiceSpecificCredentialId')
echo $GIT_USERNAME
echo $GIT_PASSWORD
echo $CREDENTIAL_ID
echo $AWS_REGION
#pip install git-remote-codecommit
git clone codecommit::$AWS_REGION://eksworkshop-app
cd eksworkshop-app
# copy app stuff and push up to repo
