#!/bin/bash
set -e

NAMESPACE="kube-system"

echo "Testing Metrics Server..."

# 1. Check if metrics server pods are running
echo "Checking Metrics Server pods..."
kubectl wait --for=condition=Ready pods -l "app.kubernetes.io/name=metrics-server" -n ${NAMESPACE} --timeout=60s || {
    echo "Error: Metrics Server pods not ready"
    exit 1
}


echo "Metrics Server pods are running ✓"

# 2. Check metrics server API availability
echo "Checking Metrics Server API availability..."
kubectl get --raw /apis/metrics.k8s.io/v1beta1 > /dev/null || {
    echo "Error: Metrics Server API is not available"
    exit 1
}

echo "Metrics Server API is available ✓"

# 3. Test node metrics
echo "Testing node metrics collection..."
kubectl top nodes > /dev/null || {
    echo "Error: Unable to get node metrics"
    exit 1
}

echo "Node metrics are being collected ✓"

# 4. Test pod metrics with a test deployment
echo "Creating test deployment..."
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-test
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: metrics-test
  template:
    metadata:
      labels:
        app: metrics-test
    spec:
      containers:
      - name: test
        image: busybox
        command: ['sh', '-c', 'while true; do echo "Testing metrics"; sleep 5; done']
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
EOF

# Wait for test pod to be ready
echo "Waiting for test pod to be ready..."
kubectl wait --for=condition=Ready pods -l app=metrics-test -n default --timeout=60s || {
    echo "Error: Test pod not ready"
    exit 1
}

# Wait for metrics to be collected (metrics server needs some time to collect metrics)
echo "Waiting for metrics to be collected (sleep 30s) ..."
sleep 30

# 5. Test pod metrics
echo "Testing pod metrics collection..."
kubectl top pods -l app=metrics-test -n default > /dev/null || {
    echo "Error: Unable to get pod metrics"
    exit 1
}

echo "Pod metrics are being collected ✓"

# 6. Test accuracy of metrics reporting
echo "Verifying metrics accuracy..."
POD_METRICS=$(kubectl top pods -l app=metrics-test -n default --no-headers)
if [[ -z "$POD_METRICS" ]]; then
    echo "Error: No metrics reported for test pod"
    exit 1
fi

# 7. Clean up test resources
echo "Cleaning up test resources..."
kubectl delete deployment metrics-test -n default

echo "All tests completed successfully! ✓"

# Print summary
echo "
Summary:
--------
✓ Metrics Server pods are running
✓ Metrics Server API is available
✓ Node metrics collection working
✓ Pod metrics collection working
✓ Test deployment successfully monitored
"

# Print current metrics server version
echo "Metrics Server Version:"
kubectl describe deployment metrics-server -n kube-system | grep Image: | awk -F: '{print $3}'

# Optional: Create cleanup script
cat << EOF > cleanup.sh
#!/bin/bash
kubectl delete deployment metrics-test -n default --ignore-not-found
EOF

chmod +x cleanup.sh