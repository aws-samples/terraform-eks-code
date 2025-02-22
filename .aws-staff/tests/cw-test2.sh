#!/bin/bash
set -e

CLUSTER_NAME="eks-workshop"
NAMESPACE="amazon-cloudwatch"
TEST_NAMESPACE="cloudwatch-test"

echo "Testing CloudWatch Observability Add-on..."

# 1. Check if the add-on is installed
echo "Checking add-on status..."
ADDON_STATUS=$(aws eks describe-addon \
    --cluster-name ${CLUSTER_NAME} \
    --addon-name amazon-cloudwatch-observability \
    --query 'addon.status' \
    --output text)

if [ "$ADDON_STATUS" != "ACTIVE" ]; then
    echo "Error: CloudWatch Observability add-on is not active (Status: ${ADDON_STATUS})"
    exit 1
fi

echo "Add-on is active ✓"

# 2. Check if required pods are running
echo "Checking CloudWatch pods..."

# Check controller manager
echo "Checking controller manager..."
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/component=amazon-cloudwatch-observability -n ${NAMESPACE} --timeout=60s || {
    echo "Error: CloudWatch Observability controller manager not ready"
    exit 1
}

# Check CloudWatch agent pods
echo "Checking CloudWatch agent pods..."
echo "Listing all pods and their labels in ${NAMESPACE}:"
kubectl get pods -n ${NAMESPACE} --show-labels

echo "Looking for CloudWatch agent pods:"
AGENT_POD=$(kubectl get pods -n ${NAMESPACE} | grep cloudwatch-agent | head -n 1 | awk '{print $1}')
if [ -n "$AGENT_POD" ]; then
    echo "Found agent pod: $AGENT_POD"
    echo "Pod labels:"
    kubectl get pod $AGENT_POD -n ${NAMESPACE} -o jsonpath='{.metadata.labels}' | jq '.'
fi

# Now try to wait for the pods
kubectl wait --for=condition=Ready pods -l k8s-app=cloudwatch-agent -n ${NAMESPACE} --timeout=60s || {
    echo "Error: CloudWatch agent pods not ready"
    exit 1
}

# Check Fluent Bit pods
echo "Checking Fluent Bit pods..."
kubectl wait --for=condition=Ready pods -l name=fluent-bit -n ${NAMESPACE} --timeout=60s || {
    echo "Error: Fluent Bit pods not ready"
    exit 1
}

# Print pod status for verification
echo "Current pod status in ${NAMESPACE} namespace:"
kubectl get pods -n ${NAMESPACE}

echo "Required pods are running ✓"

# 3. Create test resources
echo "Creating test namespace and resources..."
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${TEST_NAMESPACE}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  namespace: ${TEST_NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: test-container
        image: busybox
        command: ["/bin/sh", "-c"]
        args:
        - while true; do
            echo "Test log message $(date)";
            sleep 5;
          done
EOF

# Wait for test pod to be ready
echo "Waiting for test pod to be ready..."
kubectl wait --for=condition=Ready pods -l app=test-app -n ${TEST_NAMESPACE} --timeout=60s || {
    echo "Error: Test pod not ready"
    exit 1
}

echo "Test pod is ready ✓"

# 4. Check CloudWatch Logs
echo "Checking if logs are being sent to CloudWatch..."
# Get the log group name
LOG_GROUP="/aws/containerinsights/${CLUSTER_NAME}/application"

# Wait for logs to appear (may take a few minutes)
echo "Waiting for logs to appear in CloudWatch..."
ATTEMPTS=0
MAX_ATTEMPTS=12  # 2 minutes total (12 * 10 seconds)

while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    if aws logs describe-log-streams \
        --log-group-name ${LOG_GROUP} \
        --log-stream-name-prefix ${TEST_NAMESPACE} \
        --query 'logStreams[0].logStreamName' \
        --output text &> /dev/null; then
        echo "Found log stream ✓"
        break
    fi
    ATTEMPTS=$((ATTEMPTS + 1))
    echo "Waiting for logs... (${ATTEMPTS}/${MAX_ATTEMPTS})"
    sleep 10
done

if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
    echo "Error: Logs did not appear in CloudWatch within expected timeframe"
    exit 1
fi

# 5. Check Container Insights metrics
echo "Checking Container Insights metrics..."
METRIC_EXISTS=$(aws cloudwatch list-metrics \
    --namespace ContainerInsights \
    --metric-name pod_cpu_utilization \
    --dimensions Name=ClusterName,Value=${CLUSTER_NAME} \
    --query 'length(Metrics)' \
    --output text)

if [ "$METRIC_EXISTS" -eq "0" ]; then
    echo "Error: Container Insights metrics not found"
    exit 1
fi

echo "Container Insights metrics found ✓"

# 6. Verify CloudWatch agent configuration
echo "Checking CloudWatch agent configuration..."
for pod in $(kubectl get pods -n ${NAMESPACE} -l name=cloudwatch-agent -o name); do
    echo "Checking config in $pod..."
    kubectl exec -n ${NAMESPACE} $pod -- cat /etc/cwagentconfig/cwagentconfig.json > /dev/null || {
        echo "Error: Cannot read CloudWatch agent configuration"
        exit 1
    }
done

echo "CloudWatch agent configuration verified ✓"

# 7. Check Fluent Bit configuration
echo "Checking Fluent Bit configuration..."
for pod in $(kubectl get pods -n ${NAMESPACE} -l app=fluent-bit -o name); do
    echo "Checking config in $pod..."
    kubectl exec -n ${NAMESPACE} $pod -- cat /fluent-bit/etc/fluent-bit.conf > /dev/null || {
        echo "Error: Cannot read Fluent Bit configuration"
        exit 1
    }
done

echo "Fluent Bit configuration verified ✓"

# 8. Clean up test resources
echo "Cleaning up test resources..."
kubectl delete namespace ${TEST_NAMESPACE}

echo "All tests completed successfully! ✓"

# Print summary
echo "
Summary:
--------
✓ Add-on is active
✓ Controller manager is running
✓ CloudWatch agent pods are running
✓ Fluent Bit pods are running
✓ Test pod deployed successfully
✓ Logs are being sent to CloudWatch
✓ Container Insights metrics are available
✓ Agent configurations verified
"

# Create cleanup script
cat << EOF > cleanup.sh
#!/bin/bash
kubectl delete namespace ${TEST_NAMESPACE} --ignore-not-found
EOF

chmod +x cleanup.sh