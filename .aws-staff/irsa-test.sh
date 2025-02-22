#!/bin/bash
set -e

# Generate a random string for bucket name
RANDOM_STRING=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 8 | head -n 1)
BUCKET_NAME="irsa-test-${RANDOM_STRING}"
CLUSTER_NAME="eks-workshop"  # Replace with your cluster name
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
OIDC_PROVIDER=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | sed 's/https:\/\///')
NAMESPACE="irsa-test"
SA_NAME="s3-test-sa"

echo "Using bucket name: ${BUCKET_NAME}"

# Create S3 bucket
echo "Creating S3 bucket..."
aws s3api create-bucket \
    --bucket ${BUCKET_NAME} \
    --create-bucket-configuration LocationConstraint=$(aws configure get region) || {
        echo "Failed to create bucket"
        exit 1
    }

# Wait for bucket to be available
echo "Waiting for bucket to be available..."
aws s3api wait bucket-exists --bucket ${BUCKET_NAME}

# Create the IAM policy for S3 access
echo "Creating IAM policy..."
cat << EOF > s3-test-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET_NAME}",
                "arn:aws:s3:::${BUCKET_NAME}/*"
            ]
        }
    ]
}
EOF

# Create the IAM policy
POLICY_ARN=$(aws iam create-policy \
    --policy-name "s3-test-policy-${RANDOM_STRING}" \
    --policy-document file://s3-test-policy.json \
    --query 'Policy.Arn' \
    --output text)

echo "Created policy: ${POLICY_ARN}"

# Create the IAM role trust policy
echo "Creating trust policy..."
cat << EOF > trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:${NAMESPACE}:${SA_NAME}",
          "${OIDC_PROVIDER}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF

# Create the IAM role
ROLE_NAME="s3-test-role-${RANDOM_STRING}"
echo "Creating IAM role: ${ROLE_NAME}"
aws iam create-role \
    --role-name ${ROLE_NAME} \
    --assume-role-policy-document file://trust-policy.json

# Attach the S3 policy to the role
echo "Attaching policy to role..."
aws iam attach-role-policy \
    --role-name ${ROLE_NAME} \
    --policy-arn ${POLICY_ARN}

# Create the Kubernetes namespace and service account
echo "Creating Kubernetes resources..."
cat << EOF > sa.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${SA_NAME}
  namespace: ${NAMESPACE}
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}
EOF

kubectl apply -f sa.yaml

# Create a test pod
echo "Creating test pod..."
cat << EOF > test-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: aws-cli-test
  namespace: ${NAMESPACE}
spec:
  serviceAccountName: ${SA_NAME}
  containers:
  - name: aws-cli
    image: amazon/aws-cli:2.11.0
    command: 
      - sleep
      - "3600"
  restartPolicy: Never
EOF

kubectl apply -f test-pod.yaml

# Wait for pod to be ready
echo "Waiting for pod to be ready..."
kubectl wait --for=condition=Ready pod/aws-cli-test -n ${NAMESPACE} --timeout=60s

echo "Running tests..."
echo "1. Verifying IAM role..."
kubectl exec -n ${NAMESPACE} aws-cli-test -- aws sts get-caller-identity

echo "2. Testing S3 access..."
# Create and upload test file
echo "Creating and uploading test file..."
kubectl exec -n ${NAMESPACE} aws-cli-test -- sh -c "echo 'IRSA test successful' > test.txt"
kubectl exec -n ${NAMESPACE} aws-cli-test -- aws s3 cp test.txt s3://${BUCKET_NAME}/

# List bucket contents
echo "Listing bucket contents..."
kubectl exec -n ${NAMESPACE} aws-cli-test -- aws s3 ls s3://${BUCKET_NAME}/

# Download the file back
echo "Downloading test file..."
kubectl exec -n ${NAMESPACE} aws-cli-test -- aws s3 cp s3://${BUCKET_NAME}/test.txt downloaded.txt

# Delete the file
echo "Testing delete operation..."
kubectl exec -n ${NAMESPACE} aws-cli-test -- aws s3 rm s3://${BUCKET_NAME}/test.txt

echo "Tests completed successfully!"

# Create cleanup script
cat << 'EOF' > cleanup.sh
#!/bin/bash
set -e

# Source variables
source ./test-variables.env

echo "Starting cleanup..."

# Delete Kubernetes resources
echo "Deleting Kubernetes resources..."
kubectl delete pod aws-cli-test -n ${NAMESPACE} --ignore-not-found
kubectl delete namespace ${NAMESPACE} --ignore-not-found

# Detach and delete IAM role policy
echo "Cleaning up IAM resources..."
aws iam detach-role-policy --role-name ${ROLE_NAME} --policy-arn ${POLICY_ARN}
aws iam delete-role --role-name ${ROLE_NAME}
aws iam delete-policy --policy-arn ${POLICY_ARN}

# Empty and delete S3 bucket
echo "Cleaning up S3 bucket..."
aws s3 rm s3://${BUCKET_NAME} --recursive
aws s3api delete-bucket --bucket ${BUCKET_NAME}

echo "Cleanup completed successfully!"
EOF

chmod +x cleanup.sh

# Save variables for cleanup
cat << EOF > test-variables.env
BUCKET_NAME=${BUCKET_NAME}
ROLE_NAME=${ROLE_NAME}
POLICY_ARN=${POLICY_ARN}
NAMESPACE=${NAMESPACE}
EOF

echo "Setup complete! Test bucket name is: ${BUCKET_NAME}"
echo "To clean up resources, run: ./cleanup.sh"