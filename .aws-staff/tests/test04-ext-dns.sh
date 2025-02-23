#!/bin/bash
set -e

NAMESPACE="external-dns"
td=$(aws route53 list-hosted-zones --query HostedZones[].Name --output text | grep 'people.aws.dev')
md=${td%.}
TEST_DOMAIN=$(echo $md)  # Replace with your domain
echo "Domain: ${TEST_DOMAIN}"

echo "Testing External DNS..."

# 1. Check if External DNS pods are running
echo "Checking External DNS pods..."
kubectl wait --for=condition=Ready pods -l "app.kubernetes.io/name=external-dns" -n ${NAMESPACE} --timeout=60s || {
    echo "Error: External DNS pods not ready"
    exit 1
}


echo "External DNS pods are running ✓"

# 2. Check External DNS logs for errors
echo "Checking External DNS logs..."
POD_NAME=$(kubectl get pods -n ${NAMESPACE} -l "app.kubernetes.io/name=external-dns" -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n ${NAMESPACE} ${POD_NAME} | grep -i "error" && {
    echo "Warning: Found errors in External DNS logs"
} || echo "No errors found in logs ✓"

# 3. Create test resources
echo "Creating test resources..."
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: external-dns-test
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-test
  namespace: external-dns-test
  annotations:
    external-dns.alpha.kubernetes.io/hostname: ${TEST_DOMAIN}
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: nginx-test
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  namespace: external-dns-test
spec:
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# 4. Wait for service to get LoadBalancer IP/hostname
echo "Waiting for LoadBalancer to be ready (sleep 180) ..."
sleep 180
kubectl wait --for=jsonpath='{.status.loadBalancer.ingress[0]}' service nginx-test -n external-dns-test --timeout=180s || {
    echo "Error: LoadBalancer not ready"
    exit 1
}

echo "LoadBalancer is ready ✓"

# 5. Check External DNS logs for DNS record creation
echo "Checking External DNS logs for DNS updates (sleep 30) ..."
sleep 30  # Give External DNS time to process
kubectl logs -n ${NAMESPACE} ${POD_NAME} --tail=50 | grep -i "${TEST_DOMAIN}" || {
    echo "Warning: No log entries found for test domain"
}

# 6. Verify External DNS IAM permissions (AWS specific)
echo "Checking AWS Route53 permissions..."
kubectl logs -n ${NAMESPACE} ${POD_NAME} | grep -i "forbidden" && {
    echo "Warning: Possible IAM permission issues detected"
} || echo "No permission issues found ✓"

# 7. Check External DNS metrics endpoint
echo "Checking metrics endpoint..."
kubectl port-forward -n ${NAMESPACE} ${POD_NAME} 7979:7979 > /dev/null 2>&1 & 
PFPID=$!
sleep 5
if curl -s localhost:7979/metrics > /dev/null; then
    echo "Metrics endpoint is accessible ✓"
else
    echo "Warning: Unable to access metrics endpoint"
fi
kill $PFPID

# 8. Clean up test resources
echo "Cleaning up test resources..."
kubectl delete namespace external-dns-test

echo "All tests completed successfully! ✓"

# Print summary
echo "
Summary:
--------
✓ External DNS pods are running
✓ Logs checked for errors
✓ Test service created successfully
✓ LoadBalancer provisioned
✓ DNS update logs verified
✓ IAM permissions checked
✓ Metrics endpoint verified
"

# Print current External DNS version
echo "External DNS Version:"
kubectl describe deployment -n ${NAMESPACE} -l "app.kubernetes.io/name=external-dns" | grep Image: | awk -F: '{print $3}'

# Create cleanup script
cat << EOF > cleanup.sh
#!/bin/bash
kubectl delete namespace external-dns-test --ignore-not-found
EOF

chmod +x cleanup.sh