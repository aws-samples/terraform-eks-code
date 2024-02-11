export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=$(aws configure get region)
cat << EOF > grafana_trust_policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "grafana.amazonaws.com"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "aws:SourceAccount": "${ACCOUNT_ID}"
                },
                "StringLike": {
                    "aws:SourceArn": "arn:aws:grafana:${AWS_REGION}:${ACCOUNT_ID}:/workspaces/*"
                }
            }
        }
    ]
}
EOF

aws iam create-role --role-name keycloak-blog-grafana-role \
    --assume-role-policy-document file://grafana_trust_policy.json