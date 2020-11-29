# check app it in clone - copy files push
test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || "echo AWS_REGION is not set && exit"
aws iam attach-user-policy --user-name git-user --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitPowerUser
aws iam create-service-specific-credential --user-name git-user --service-name codecommit.amazonaws.com | tee /tmp/gituser_output.json
GIT_USERNAME=$(cat /tmp/gituser_output.json | jq -r '.ServiceSpecificCredential.ServiceUserName')
GIT_PASSWORD=$(cat /tmp/gituser_output.json | jq -r '.ServiceSpecificCredential.ServicePassword')
CREDENTIAL_ID=$(cat /tmp/gituser_output.json | jq -r '.ServiceSpecificCredential.ServiceSpecificCredentialId')
test -n "$GIT_USERNAME" && echo GIT_USERNAME is "$GIT_USERNAME" || "echo GIT_USERNAME is not set && exit"
git clone codecommit::$AWS_REGION://eksworkshop-app


#

# auth pipeline
# aws eks

eksctl create iamidentitymapping \
  --cluster mycluster1 \
  --arn arn:aws:iam::${ACCOUNT_ID}:role/codebuild-eks-cicd-build-app-service-role \
  --username admin \
  --group system:masters

# envoke
cd eksworkshop-app
cp ../*.yml .
git add --all && git commit -m "Initial commit." && git push
