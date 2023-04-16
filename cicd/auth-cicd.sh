test -n "$ACCOUNT_ID" && echo ACCOUNT_ID is "$ACCOUNT_ID" || "echo ACCOUNT_ID is not set && exit"
# get the workshop id from SSM
WSID=$(aws ssm get-parameter --name /workshop/tf-eks/id --query Parameter.Value --output text)
ROLE="    - rolearn: arn:aws:iam::$ACCOUNT_ID:role/$WSID-codebuild-eks-service-role\n      username: build\n      groups:\n        - system:masters"
#
kubectl get -n kube-system configmap/aws-auth -o yaml | awk "/mapRoles: \|/{print;print \"$ROLE\";next}1" > /tmp/aws-auth-patch.yml
#
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat /tmp/aws-auth-patch.yml)"
#