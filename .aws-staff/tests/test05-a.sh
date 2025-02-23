#!/bin/bash
set -e

NAMESPACE="external-secrets"
TEST_NAMESPACE="external-secrets-test"
SECRET_NAME="test-secret"


echo "Testing External Secrets Operator..."
# Print versions
echo "External Secrets Version:"
kubectl get deployment -n ${NAMESPACE} external-secrets -o jsonpath='{.spec.template.spec.containers[0].image}'

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
echo "Creating test namespace... ${TEST_NAMESPACE}"
kubectl create namespace ${TEST_NAMESPACE}

# 3. Create SecretStore with AWS Secrets Manager configuration
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
      region: ${AWS_REGION}
      auth:
        jwt:
          serviceAccountRef:
            name: default
EOF

# 4. Create a test secret in AWS Secrets Manager
echo "Creating external-secrets-test in AWS Secrets Manager... (AWS cli)"
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

echo "SECRET_NAME ${SECRET_NAME}"


kubectl get secret ${SECRET_NAME} -n ${TEST_NAMESPACE}


# 9. Clean up resources
#echo "Cleaning up resources..."
#kubectl delete namespace ${TEST_NAMESPACE}
#aws secretsmanager delete-secret --secret-id external-secrets-test --force-delete-without-recovery

#echo "All tests completed successfully! ✓"

# Print summary


# Create cleanup script
cat << EOF > cleanup.sh
#!/bin/bash
kubectl delete namespace ${TEST_NAMESPACE} --ignore-not-found
aws secretsmanager delete-secret --secret-id external-secrets-test --force-delete-without-recovery --region ${AWS_REGION} || true
EOF

chmod +x cleanup.sh

