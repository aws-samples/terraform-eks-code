#!/bin/bash
set -e

CLUSTER_NAME="eks-workshop"  # Replace with your cluster name
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
kubectl wait --for=condition=Ready pods -l name=aws-cloudwatch-metrics -n amazon-cloudwatch --timeout=60s || {
    echo "Error: CloudWatch metrics pods not ready"
    exit 1
}

kubectl wait --for=condition=Ready pods -l k8s-app=fluent-bit -n amazon-cloudwatch --timeout=60s || {
    echo "Error: Fluent Bit pods not ready"
    exit 1
}

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

# 6. Optional: Clean up test resources
echo "Cleaning up test resources..."
kubectl delete namespace ${TEST_NAMESPACE}

echo "All tests completed successfully! ✓"

# Print summary
echo "
Summary:
--------
✓ Add-on is active
✓ Required pods are running
✓ Test pod deployed successfully
✓ Logs are being sent to CloudWatch
✓ Container Insights metrics are available
"

# Optional: Create cleanup script
cat << 'EOF' > cleanup.sh
#!/bin/bash
kubectl delete namespace ${TEST_NAMESPACE} --ignore-not-found
EOF

chmod +x cleanup.sh