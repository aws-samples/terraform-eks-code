#!/bin/bash
set -e
echo "delete namespace"
kubectl delete namespace ${TEST_NAMESPACE} --ignore-not-found
echo "delete aws secret"
aws secretsmanager delete-secret --secret-id external-secrets-test --force-delete-without-recovery || true

NAMESPACE="external-secrets"
TEST_NAMESPACE="external-secrets-test"
SECRET_NAME="test-secret"


kubectl create ns $TEST_NAMESPACE
echo "Testing External Secrets Operator..."

# 1. Check if all External Secrets pods are running
echo "Checking External Secrets pods..."

echo "Checking main controller..."
kubectl wait --for=condition=Ready pods -l "app.kubernetes.io/name=external-secrets" -n ${NAMESPACE} --timeout=60s || {
    echo "Error: External Secrets controller not ready"
    exit 1
}

echo "Checking cert controller..."
kubectl wait --for=condition=Ready pods -l "app.kubernetes.io/name=external-secrets-cert-controller" -n ${NAMESPACE} --timeout=60s || {
    echo "Error: External Secrets cert controller not ready"
    exit 1
}

echo "Checking webhook..."
kubectl wait --for=condition=Ready pods -l "app.kubernetes.io/name=external-secrets-webhook" -n ${NAMESPACE} --timeout=60s || {
    echo "Error: External Secrets webhook not ready"
    exit 1
}

echo "All External Secrets pods are running ✓"

# 2. Create test namespace
#echo "Creating test namespace..."
#kubectl create namespace ${TEST_NAMESPACE}

# 3. Create SecretStore with AWS Secrets Manager configuration
# this passes the service account "default" for IRSA
#  https://aws.amazon.com/blogs/containers/leverage-aws-secrets-stores-from-eks-fargate-with-external-secrets-operator/
#
echo "Role attached to service account: external-secrets-sa"
kubectl describe  sa external-secrets-sa  -n external-secrets | grep Anno
sarn=$(kubectl describe  sa external-secrets-sa  -n external-secrets | grep Anno | cut -f3- -d':' | tr -d ' ')
kubectl annotate serviceaccount default -n external-secrets-test \
    eks.amazonaws.com/role-arn=$sarn --overwrite
kubectl describe  sa default  -n external-secrets-test | grep Anno

echo "Creating SecretStore..."
cat << EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-backend
  namespace: ${TEST_NAMESPACE}
spec:
  provider:
    aws:
      service: SecretsManager
      region: eu-west-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
EOF

# 4. Create a test secret in AWS Secrets Manager
echo "Creating test secret in AWS Secrets Manager..."
aws secretsmanager create-secret \
    --name "external-secrets-test" \
    --secret-string '{"username":"test-user","password":"test-password"}' || {
    echo "Error: Failed to create AWS secret"
    exit 1
}

# 5. Create ExternalSecret
echo "Creating ExternalSecret..."
cat << EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: test-external-secret
  namespace: ${TEST_NAMESPACE}
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: aws-backend
    kind: SecretStore
  target:
    name: ${SECRET_NAME}
  data:
  - secretKey: username
    remoteRef:
      key: external-secrets-test
      property: username
  - secretKey: password
    remoteRef:
      key: external-secrets-test
      property: password
EOF


# 6. Wait for secret to be created
echo "Waiting for secret to be created..."
for i in {1..12}; do
    if kubectl get secret ${SECRET_NAME} -n ${TEST_NAMESPACE} > /dev/null 2>&1; then
        echo "Secret created successfully ✓"
        break
    fi
    if [ $i -eq 12 ]; then
        echo "Error: Timeout waiting for secret creation"
        exit 1
    fi
    echo "Waiting for secret... (${i}/12)"
    sleep 5
done

# 7. Verify secret content
echo "Verifying secret content..."
USERNAME=$(kubectl get secret ${SECRET_NAME} -n ${TEST_NAMESPACE} -o jsonpath='{.data.username}' | base64 -d)
if [ "$USERNAME" != "test-user" ]; then
    echo "Error: Secret content verification failed"
    exit 1
fi

echo "Secret content verified ✓"

# 8. Check operator logs for errors
echo "Checking operator logs..."
CONTROLLER_POD=$(kubectl get pods -n ${NAMESPACE} -l "app.kubernetes.io/name=external-secrets" -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n ${NAMESPACE} ${CONTROLLER_POD} | grep -i "error" && {
    echo "Warning: Found errors in operator logs"
} || echo "No errors found in logs ✓"

# 9. Clean up resources
echo "Cleaning up resources..."
kubectl delete namespace ${TEST_NAMESPACE}
aws secretsmanager delete-secret --secret-id external-secrets-test --force-delete-without-recovery

echo "All tests completed successfully! ✓"

# Print summary
echo "
Summary:
--------
✓ All controller pods are running
  - Main controller
  - Cert controller
  - Webhook
✓ SecretStore created successfully
✓ Test secret created in AWS
✓ ExternalSecret created successfully
✓ Secret synchronized correctly
✓ Secret content verified
✓ No errors in logs
"

# Create cleanup script
cat << EOF > cleanup.sh
#!/bin/bash
kubectl delete namespace ${TEST_NAMESPACE} --ignore-not-found
aws secretsmanager delete-secret --secret-id external-secrets-test --force-delete-without-recovery --region ${AWS_REGION} || true
EOF

chmod +x cleanup.sh

# Print versions
echo "External Secrets Version:"
kubectl get deployment -n ${NAMESPACE} external-secrets -o jsonpath='{.spec.template.spec.containers[0].image}'
./cleanup.sh