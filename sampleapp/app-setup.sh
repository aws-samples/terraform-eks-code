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

ROLE="    - rolearn: arn:aws:iam::$ACCOUNT_ID:role/codebuild-eks-cicd-build-app-service-role\n      username: build\n      groups:\n        - system:masters"
#
kubectl get -n kube-system configmap/aws-auth -o yaml | awk "/mapRoles: \|/{print;print \"$ROLE\";next}1" > /tmp/aws-auth-patch.yml
#
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat /tmp/aws-auth-patch.yml)"
#

#eksctl create iamidentitymapping \
#  --cluster mycluster1 \
#  --arn arn:aws:iam::${ACCOUNT_ID}:role/codebuild-eks-cicd-build-app-service-role \
#  --username admin \
#  --group system:masters


