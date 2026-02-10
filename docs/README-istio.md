# istio Stage Documentation

## Overview

The `istio` stage deploys Istio service mesh to the EKS cluster along with the Bookinfo sample application. Istio provides advanced traffic management, security, and observability features for microservices, including traffic routing, load balancing, circuit breaking, mutual TLS, and distributed tracing.

**Execution Time**: ~5-10 minutes (part of the ~40 minute total build)  
**Dependencies**: tf-setup, net, cluster, nodepool, addons (requires running cluster)  
**Outputs**: Istio control plane, ingress gateway, Bookinfo application  
**Purpose**: Service mesh for microservices management

---

## Architecture Overview

### Istio Service Mesh

```
┌─────────────────────────────────────────────────────────────────┐
│ Internet                                                         │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ Network Load Balancer (NLB)                                     │
│ - Internet-facing                                                │
│ - Cross-zone load balancing                                     │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ istio-ingress Namespace                                          │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Istio Ingress Gateway                                     │  │
│  │ - Envoy proxy                                             │  │
│  │ - Ports: 15021 (status), 80 (HTTP), 443 (HTTPS)         │  │
│  │ - LoadBalancer service                                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ istio-system Namespace                                           │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Istiod (Control Plane)                                    │  │
│  │ - Pilot: Service discovery, traffic management           │  │
│  │ - Citadel: Certificate management, mTLS                  │  │
│  │ - Galley: Configuration validation                       │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────┬────────────────────────────────────────────────┘
                 │ Configures sidecars
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ sample Namespace (istio-injection=enabled)                       │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Bookinfo Application                                      │  │
│  │                                                            │  │
│  │  Product Page (v1)                                        │  │
│  │  ├─ App Container                                         │  │
│  │  └─ Envoy Sidecar (injected)                             │  │
│  │                                                            │  │
│  │  Details (v1)                                             │  │
│  │  ├─ App Container                                         │  │
│  │  └─ Envoy Sidecar (injected)                             │  │
│  │                                                            │  │
│  │  Reviews (v1, v2, v3)                                     │  │
│  │  ├─ App Container                                         │  │
│  │  └─ Envoy Sidecar (injected)                             │  │
│  │                                                            │  │
│  │  Ratings (v1)                                             │  │
│  │  ├─ App Container                                         │  │
│  │  └─ Envoy Sidecar (injected)                             │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Key Components

### 1. Istio Base
**Purpose**: CRDs and foundational resources for Istio

**Configuration**:
- **Chart**: `base`
- **Version**: 1.24.3
- **Namespace**: `istio-system`
- **Repository**: https://istio-release.storage.googleapis.com/charts

**Resources Created**:
- Custom Resource Definitions (CRDs)
- Cluster roles and bindings
- Webhooks configuration
- Service accounts

### 2. Istiod (Control Plane)
**Purpose**: Istio control plane managing service mesh

**Configuration**:
- **Chart**: `istiod`
- **Version**: 1.24.3
- **Namespace**: `istio-system`
- **Access Logs**: Enabled (`/dev/stdout`)

**Components**:
- **Pilot**: Service discovery, traffic management, configuration distribution
- **Citadel**: Certificate authority, mTLS key/cert management
- **Galley**: Configuration validation and distribution

**Features**:
- Automatic sidecar injection
- Traffic routing rules
- Mutual TLS (mTLS)
- Policy enforcement
- Telemetry collection

### 3. Istio Ingress Gateway
**Purpose**: Entry point for external traffic into the mesh

**Configuration**:
- **Chart**: `gateway`
- **Version**: 1.24.3
- **Namespace**: `istio-ingress`
- **Service Type**: LoadBalancer (NLB)

**Ports**:
- **15021**: Status port (health checks)
- **80**: HTTP traffic → 8080
- **443**: HTTPS traffic → 443

**Load Balancer Annotations**:
```yaml
service.beta.kubernetes.io/aws-load-balancer-type: external
service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=true
```

**Features**:
- Network Load Balancer (NLB)
- IP target type (direct pod routing)
- Cross-zone load balancing
- Internet-facing

### 4. Bookinfo Sample Application
**Purpose**: Demonstrates Istio service mesh capabilities

**Architecture**:
```
Product Page (Python)
    ↓
    ├─→ Details (Ruby) - Book details
    └─→ Reviews (Java) - Book reviews
            ↓
            └─→ Ratings (Node.js) - Star ratings
```

**Services**:
1. **Product Page**: Web UI, aggregates data from other services
2. **Details**: Book details (ISBN, pages, etc.)
3. **Reviews**: Book reviews (3 versions)
   - v1: No ratings
   - v2: Black star ratings
   - v3: Red star ratings
4. **Ratings**: Star ratings backend

**Versions**:
- All services: v1
- Reviews: v1, v2, v3 (for traffic routing demos)

---

## File-by-File Breakdown

### Main Configuration

#### main.tf
**Purpose**: Deploys Istio components using Helm charts

**Provider Configuration**:
- Kubernetes provider with exec authentication
- Helm provider for chart installation
- kubectl provider for manifest application

**Istio Version**:
```terraform
locals {
  istio_chart_url     = "https://istio-release.storage.googleapis.com/charts"
  istio_chart_version = "1.24.3"
}
```

**Helm Releases**:

##### 1. istio-base
```terraform
istio-base = {
  chart         = "base"
  chart_version = local.istio_chart_version
  repository    = local.istio_chart_url
  name          = "istio-base"
  namespace     = kubernetes_namespace_v1.istio_system.metadata[0].name
  replace       = true
}
```

##### 2. istiod
```terraform
istiod = {
  chart         = "istiod"
  chart_version = local.istio_chart_version
  repository    = local.istio_chart_url
  name          = "istiod"
  namespace     = kubernetes_namespace_v1.istio_system.metadata[0].name
  replace       = true
  set = [{
    name  = "meshConfig.accessLogFile"
    value = "/dev/stdout"
  }]
}
```

**Access Logs**: Enabled for debugging and monitoring

##### 3. istio-ingress
```terraform
istio-ingress = {
  chart            = "gateway"
  chart_version    = local.istio_chart_version
  repository       = local.istio_chart_url
  name             = "istio-ingress"
  namespace        = "istio-ingress"
  create_namespace = true
  replace          = true
  
  # Port configuration (15021, 80, 443)
  # Load balancer annotations
}
```

**Namespace**:
```terraform
resource "kubernetes_namespace_v1" "istio_system" {
  metadata {
    name = "istio-system"
  }
}
```

---

### Bookinfo Application

#### bookinfo.tf
**Purpose**: Deploys Istio Bookinfo sample application

**Namespace**:
```terraform
resource "kubernetes_namespace_v1" "sample" {
  depends_on = [null_resource.restart]
  metadata {
    labels = {
      "istio-injection" = "enabled"  # Automatic sidecar injection
    }
    name = "sample"
  }
}
```

**Key Feature**: `istio-injection=enabled` label triggers automatic Envoy sidecar injection

**Service Accounts** (4):
- `bookinfo-details`
- `bookinfo-productpage`
- `bookinfo-ratings`
- `bookinfo-reviews`

**Services** (4):
- `details` (port 9080)
- `productpage` (port 9080)
- `ratings` (port 9080)
- `reviews` (port 9080)

All services are ClusterIP (internal only)

**Deployments** (6):
1. `details-v1`: Book details service
2. `productpage-v1`: Web UI
3. `ratings-v1`: Star ratings backend
4. `reviews-v1`: Reviews without ratings
5. `reviews-v2`: Reviews with black stars
6. `reviews-v3`: Reviews with red stars

**Container Images**:
- `docker.io/istio/examples-bookinfo-details-v1:1.20.2`
- `docker.io/istio/examples-bookinfo-productpage-v1:1.20.2`
- `docker.io/istio/examples-bookinfo-ratings-v1:1.20.2`
- `docker.io/istio/examples-bookinfo-reviews-v1:1.20.2`
- `docker.io/istio/examples-bookinfo-reviews-v2:1.20.2`
- `docker.io/istio/examples-bookinfo-reviews-v3:1.20.2`

---

### Synchronization

#### null_resource.tf
**Purpose**: Restarts ingress gateway after installation

```terraform
resource "null_resource" "restart" {
  triggers = {
    always_run = timestamp()
  }
  depends_on = [module.eks_blueprints_addons.helm_release]
  provisioner "local-exec" {
    command = <<EOT
       sleep 35
       kubectl rollout restart deployment istio-ingress -n istio-ingress
       sleep 10
     EOT
  }
}
```

**Why Needed?**
- Ensures ingress gateway picks up latest configuration
- Resolves potential race conditions
- 35-second delay for Istio components to stabilize

---

### Helper Scripts

#### install-istio.sh
**Purpose**: Alternative CLI-based installation

**Actions**:
1. Downloads Istio 1.24.3
2. Creates `sample` namespace
3. Enables Istio injection
4. Deploys Bookinfo application

**Usage**:
```bash
./install-istio.sh
```

#### cleanup.sh
**Purpose**: Complete Istio removal

**Actions**:
1. Deletes Istio add-ons
2. Removes Bookinfo gateway
3. Deletes Bookinfo application
4. Destroys Terraform resources
5. Uninstalls Istio with `istioctl`
6. Removes namespaces

**Usage**:
```bash
./cleanup.sh
```

---

## Istio Features

### 1. Traffic Management

**Capabilities**:
- Request routing (A/B testing, canary deployments)
- Traffic splitting (percentage-based)
- Fault injection (chaos engineering)
- Circuit breaking
- Timeouts and retries
- Load balancing algorithms

**Example - Traffic Routing**:
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
    - match:
        - headers:
            end-user:
              exact: jason
      route:
        - destination:
            host: reviews
            subset: v2
    - route:
        - destination:
            host: reviews
            subset: v1
```

### 2. Security

**Capabilities**:
- Mutual TLS (mTLS) between services
- Certificate management
- Authorization policies
- Authentication policies
- Service-to-service encryption

**Example - mTLS**:
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: sample
spec:
  mtls:
    mode: STRICT
```

### 3. Observability

**Capabilities**:
- Distributed tracing (Jaeger)
- Metrics collection (Prometheus)
- Access logs
- Service graph visualization (Kiali)
- Request telemetry

**Access Logs**: Enabled in istiod configuration (`/dev/stdout`)

### 4. Resilience

**Capabilities**:
- Circuit breaking
- Outlier detection
- Retry logic
- Timeout configuration
- Bulkhead pattern

**Example - Circuit Breaker**:
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
    outlierDetection:
      consecutiveErrors: 1
      interval: 1s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
```

---

## Accessing the Application

### Get Ingress Gateway URL

```bash
# Get the LoadBalancer DNS name
kubectl get svc -n istio-ingress istio-ingress

# Output example:
# NAME            TYPE           EXTERNAL-IP
# istio-ingress   LoadBalancer   k8s-istioing-istioing-abc123.elb.us-east-1.amazonaws.com
```

### Create Gateway and VirtualService

```bash
# Apply Bookinfo gateway configuration
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: bookinfo-gateway
  namespace: sample
spec:
  selector:
    istio: ingressgateway
  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - "*"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: bookinfo
  namespace: sample
spec:
  hosts:
    - "*"
  gateways:
    - bookinfo-gateway
  http:
    - match:
        - uri:
            exact: /productpage
        - uri:
            prefix: /static
        - uri:
            exact: /login
        - uri:
            exact: /logout
        - uri:
            prefix: /api/v1/products
      route:
        - destination:
            host: productpage
            port:
              number: 9080
EOF
```

### Access the Application

```bash
# Get the URL
export GATEWAY_URL=$(kubectl get svc -n istio-ingress istio-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Open in browser
echo "http://$GATEWAY_URL/productpage"

# Or use curl
curl http://$GATEWAY_URL/productpage
```

---

## Testing and Verification

### After Deployment

```bash
# Verify Istio installation
kubectl get pods -n istio-system
kubectl get pods -n istio-ingress

# Check Istio version
kubectl get deployment -n istio-system istiod -o jsonpath='{.spec.template.spec.containers[0].image}'

# Verify Bookinfo deployment
kubectl get pods -n sample

# Check sidecar injection (should see 2/2 for each pod)
kubectl get pods -n sample -o wide

# Verify services
kubectl get svc -n sample

# Check ingress gateway
kubectl get svc -n istio-ingress

# View Istio configuration
kubectl get gateway -n sample
kubectl get virtualservice -n sample
kubectl get destinationrule -n sample

# Check access logs
kubectl logs -n sample -l app=productpage -c istio-proxy

# Verify mTLS
kubectl exec -n sample $(kubectl get pod -n sample -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl http://details:9080/details/0 -s -o /dev/null -w "%{http_code}\n"
```

---

## Common Issues

### Issue: Pods stuck with 1/2 containers ready
**Cause**: Sidecar injection failing  
**Solution**:
```bash
# Check namespace label
kubectl get namespace sample --show-labels

# Verify istio-injection=enabled
kubectl label namespace sample istio-injection=enabled --overwrite

# Restart pods
kubectl rollout restart deployment -n sample
```

### Issue: Ingress gateway not accessible
**Causes**:
- LoadBalancer not provisioned
- Security group rules
- Gateway/VirtualService misconfigured

**Solutions**:
```bash
# Check service status
kubectl describe svc -n istio-ingress istio-ingress

# Check gateway configuration
kubectl get gateway -n sample -o yaml

# Check virtual service
kubectl get virtualservice -n sample -o yaml

# View ingress gateway logs
kubectl logs -n istio-ingress -l app=istio-ingress
```

### Issue: Services can't communicate
**Cause**: mTLS misconfiguration  
**Solution**:
```bash
# Check peer authentication
kubectl get peerauthentication -A

# Check destination rules
kubectl get destinationrule -A

# View sidecar logs
kubectl logs -n sample <pod-name> -c istio-proxy
```

### Issue: Istiod not starting
**Causes**:
- CRDs not installed
- Webhook configuration issues
- Resource constraints

**Solutions**:
```bash
# Check CRDs
kubectl get crd | grep istio

# Check istiod logs
kubectl logs -n istio-system -l app=istiod

# Verify webhooks
kubectl get mutatingwebhookconfigurations
kubectl get validatingwebhookconfigurations
```

---

## Traffic Management Examples

### Canary Deployment (90/10 split)

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews
  namespace: sample
spec:
  hosts:
    - reviews
  http:
    - route:
        - destination:
            host: reviews
            subset: v1
          weight: 90
        - destination:
            host: reviews
            subset: v3
          weight: 10
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: reviews
  namespace: sample
spec:
  host: reviews
  subsets:
    - name: v1
      labels:
        version: v1
    - name: v3
      labels:
        version: v3
```

### Fault Injection

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: ratings
  namespace: sample
spec:
  hosts:
    - ratings
  http:
    - fault:
        delay:
          percentage:
            value: 10
          fixedDelay: 5s
      route:
        - destination:
            host: ratings
            subset: v1
```

### Request Timeout

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews
  namespace: sample
spec:
  hosts:
    - reviews
  http:
    - route:
        - destination:
            host: reviews
            subset: v2
      timeout: 0.5s
```

---

## Cost Considerations

### Compute Costs
- **Istio Control Plane**: ~0.5 vCPU, 1Gi memory
- **Ingress Gateway**: ~0.5 vCPU, 1Gi memory
- **Sidecars**: ~0.1 vCPU, 128Mi per pod
- **Estimated**: +$20-40/month for Istio overhead

### Network Costs
- **NLB**: ~$16/month base + data transfer
- **Data Transfer**: $0.01/GB (first 10TB)

### Total Estimated Cost
**Monthly**: ~$36-56/month additional for Istio

---

## Best Practices

### DO:
✅ Enable automatic sidecar injection per namespace  
✅ Use mTLS for service-to-service communication  
✅ Implement circuit breakers for resilience  
✅ Monitor access logs and metrics  
✅ Use traffic routing for canary deployments  
✅ Set resource limits on sidecars  
✅ Use destination rules for load balancing  
✅ Implement retry and timeout policies

### DON'T:
❌ Inject sidecars into system namespaces  
❌ Skip mTLS configuration  
❌ Ignore sidecar resource consumption  
❌ Use overly complex routing rules  
❌ Forget to configure health checks  
❌ Skip monitoring and observability  
❌ Use Istio for simple applications (overhead)  
❌ Ignore version compatibility

---

## Related Documentation

- **addons Stage**: See `docs/README-addons.md` for add-ons configuration
- **sampleapp Stage**: See `docs/README-sampleapp.md` for application deployment
- **Istio Documentation**: https://istio.io/latest/docs/
- **Bookinfo Application**: https://istio.io/latest/docs/examples/bookinfo/
- **Istio on EKS**: https://aws.amazon.com/blogs/containers/istio-on-amazon-eks/

---

## Summary

The istio stage deploys a complete service mesh solution with:
- **Istio 1.24.3**: Latest stable version
- **Control Plane (Istiod)**: Service discovery, traffic management, security
- **Ingress Gateway**: External traffic entry point with NLB
- **Bookinfo Application**: Sample microservices app demonstrating Istio features
- **Automatic Sidecar Injection**: Envoy proxies injected into pods
- **Traffic Management**: Routing, load balancing, fault injection
- **Security**: mTLS, authentication, authorization
- **Observability**: Access logs, metrics, distributed tracing

This configuration provides production-ready service mesh capabilities for advanced microservices management, including traffic control, security, and observability features.
