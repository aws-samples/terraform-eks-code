# sampleapp Stage Documentation

## Overview

The `sampleapp` stage deploys a complete microservices-based e-commerce application called "Retail Store Sample" to the EKS cluster. This application demonstrates a production-like architecture with multiple services, databases, message queues, and a web UI, all deployed using Terraform-managed Kubernetes resources.

**Execution Time**: ~3-5 minutes (part of the ~40 minute total build)  
**Dependencies**: tf-setup, net, cluster, nodepool, addons (requires running cluster with nodes)  
**Outputs**: Running e-commerce application with LoadBalancer  
**Application**: AWS Retail Store Sample (microservices demo)

---

## Architecture Overview

### Microservices Application

```
┌─────────────────────────────────────────────────────────────────┐
│ Internet                                                         │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ Network Load Balancer (NLB)                                     │
│ - Internet-facing                                                │
│ - Port 80 → UI Service                                          │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ sampleapp Namespace                                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Frontend                                                  │  │
│  │ - UI Service (Web Interface)                             │  │
│  │ - Assets Service (Static files)                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Backend Services                                          │  │
│  │ - Catalog Service → MySQL Database                       │  │
│  │ - Carts Service → DynamoDB (external)                    │  │
│  │ - Orders Service → PostgreSQL + RabbitMQ                 │  │
│  │ - Checkout Service → Redis Cache                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Databases (StatefulSets)                                  │  │
│  │ - MySQL (catalog-mysql)                                   │  │
│  │ - PostgreSQL (orders-postgresql)                          │  │
│  │ - RabbitMQ (orders-rabbitmq)                              │  │
│  │ - Redis (checkout-redis)                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Application Components

### Frontend Services

#### 1. UI Service
**Purpose**: Web interface for the e-commerce application

**Configuration**:
- **Image**: `public.ecr.aws/aws-containers/retail-store-sample-ui:0.8.4`
- **Replicas**: 1
- **Resources**: 128m CPU, 512Mi memory
- **Port**: 8080 (HTTP)
- **Service Type**: LoadBalancer (internet-facing NLB)
- **Health Checks**: Liveness probe on `/actuator/health/liveness`

**Features**:
- Java-based Spring Boot application
- Prometheus metrics endpoint
- Read-only root filesystem
- Non-root user (UID 1000)
- Temporary volume for /tmp

**Service Account**: `ui` (with IRSA capability)

#### 2. Assets Service
**Purpose**: Serves static assets (images, CSS, JavaScript)

**Configuration**:
- **Image**: `public.ecr.aws/aws-containers/retail-store-sample-assets:0.8.4`
- **Replicas**: 1
- **Resources**: 128m CPU, 128Mi memory
- **Port**: 8080
- **Service Type**: ClusterIP (internal only)

**Features**:
- Nginx-based static file server
- Lightweight resource footprint
- Security hardened

---

### Backend Services

#### 3. Catalog Service
**Purpose**: Product catalog management

**Configuration**:
- **Image**: `public.ecr.aws/aws-containers/retail-store-sample-catalog:0.8.4`
- **Replicas**: 1
- **Resources**: 128m CPU, 512Mi memory
- **Database**: MySQL (StatefulSet)
- **Port**: 8080

**Database**:
- **Type**: MySQL 5.7
- **Storage**: Persistent volume (30Gi)
- **Credentials**: Kubernetes Secret
- **Service**: ClusterIP (catalog-mysql)

**Features**:
- RESTful API for product data
- Database connection pooling
- Health checks and readiness probes

#### 4. Carts Service
**Purpose**: Shopping cart management

**Configuration**:
- **Image**: `public.ecr.aws/aws-containers/retail-store-sample-carts:0.8.4`
- **Replicas**: 1
- **Resources**: 128m CPU, 512Mi memory
- **Database**: DynamoDB (external AWS service)
- **Port**: 8080

**DynamoDB Integration**:
- Uses IRSA for authentication
- No credentials in code
- Serverless, fully managed
- Auto-scaling capacity

**Features**:
- Session-based cart storage
- DynamoDB SDK integration
- IRSA service account

#### 5. Orders Service
**Purpose**: Order processing and management

**Configuration**:
- **Image**: `public.ecr.aws/aws-containers/retail-store-sample-orders:0.8.4`
- **Replicas**: 1
- **Resources**: 128m CPU, 512Mi memory
- **Database**: PostgreSQL (StatefulSet)
- **Message Queue**: RabbitMQ (StatefulSet)
- **Port**: 8080

**PostgreSQL Database**:
- **Version**: PostgreSQL 16
- **Storage**: Persistent volume (30Gi)
- **Credentials**: Kubernetes Secret
- **Service**: ClusterIP (orders-postgresql)

**RabbitMQ**:
- **Version**: RabbitMQ 3.11
- **Storage**: Persistent volume (30Gi)
- **Credentials**: Kubernetes Secret
- **Service**: ClusterIP (orders-rabbitmq)
- **Ports**: 5672 (AMQP), 15672 (Management UI)

**Features**:
- Asynchronous order processing
- Event-driven architecture
- Message queue for order events

#### 6. Checkout Service
**Purpose**: Checkout process and payment

**Configuration**:
- **Image**: `public.ecr.aws/aws-containers/retail-store-sample-checkout:0.8.4`
- **Replicas**: 1
- **Resources**: 256m CPU, 512Mi memory
- **Cache**: Redis (Deployment)
- **Port**: 8080

**Redis Cache**:
- **Version**: Redis 6.0
- **Type**: Deployment (ephemeral)
- **Service**: ClusterIP (checkout-redis)
- **Port**: 6379

**Features**:
- Session management
- Cart data caching
- Fast checkout process

---

## Resource Types

### Deployments
Standard Kubernetes Deployments for stateless services:
- `ui` - Web interface
- `assets` - Static files
- `catalog` - Product catalog
- `carts` - Shopping carts
- `orders` - Order management
- `checkout` - Checkout process
- `carts-dynamodb` - DynamoDB proxy
- `checkout-redis` - Redis cache

### StatefulSets
Kubernetes StatefulSets for stateful databases:
- `catalog-mysql` - MySQL database for catalog
- `orders-postgresql` - PostgreSQL database for orders
- `orders-rabbitmq` - RabbitMQ message queue

**Why StatefulSets?**
- Stable network identities
- Persistent storage
- Ordered deployment and scaling
- Graceful shutdown

### Services
Kubernetes Services for network access:
- **LoadBalancer**: `ui` (internet-facing NLB)
- **ClusterIP**: All other services (internal only)

### ConfigMaps
Configuration for each service:
- Environment variables
- Application properties
- Service endpoints

### Secrets
Sensitive data for databases:
- `catalog-db` - MySQL credentials
- `orders-db` - PostgreSQL credentials
- `orders-rabbitmq` - RabbitMQ credentials

### Service Accounts
IRSA-enabled service accounts for AWS access:
- `ui`, `assets`, `catalog`, `carts`, `orders`, `checkout`

---

## File Organization

### Provider Configuration
- **k8s.tf**: Kubernetes provider using local kubeconfig

### Namespace
- **kubernetes_namespace_v1__sampleapp.tf**: Creates `sampleapp` namespace

### Deployments (8 files)
- `kubernetes_deployment_v1__sampleapp__ui.tf`
- `kubernetes_deployment_v1__sampleapp__assets.tf`
- `kubernetes_deployment_v1__sampleapp__catalog.tf`
- `kubernetes_deployment_v1__sampleapp__carts.tf`
- `kubernetes_deployment_v1__sampleapp__carts-dynamodb.tf`
- `kubernetes_deployment_v1__sampleapp__orders.tf`
- `kubernetes_deployment_v1__sampleapp__checkout.tf`
- `kubernetes_deployment_v1__sampleapp__checkout-redis.tf`

### StatefulSets (3 files)
- `kubernetes_stateful_set_v1__sampleapp__catalog-mysql.tf`
- `kubernetes_stateful_set_v1__sampleapp__orders-postgresql.tf`
- `kubernetes_stateful_set_v1__sampleapp__orders-rabbitmq.tf`

### Services (11 files)
- `kubernetes_service_v1__sampleapp__ui.tf` (LoadBalancer)
- `kubernetes_service_v1__sampleapp__assets.tf`
- `kubernetes_service_v1__sampleapp__catalog.tf`
- `kubernetes_service_v1__sampleapp__catalog-mysql.tf`
- `kubernetes_service_v1__sampleapp__carts.tf`
- `kubernetes_service_v1__sampleapp__carts-dynamodb.tf`
- `kubernetes_service_v1__sampleapp__orders.tf`
- `kubernetes_service_v1__sampleapp__orders-postgresql.tf`
- `kubernetes_service_v1__sampleapp__orders-rabbitmq.tf`
- `kubernetes_service_v1__sampleapp__checkout.tf`
- `kubernetes_service_v1__sampleapp__checkout-redis.tf`

### ConfigMaps (6 files)
- `kubernetes_config_map_v1__sampleapp__ui.tf`
- `kubernetes_config_map_v1__sampleapp__assets.tf`
- `kubernetes_config_map_v1__sampleapp__catalog.tf`
- `kubernetes_config_map_v1__sampleapp__carts.tf`
- `kubernetes_config_map_v1__sampleapp__orders.tf`
- `kubernetes_config_map_v1__sampleapp__checkout.tf`

### Secrets (3 files)
- `kubernetes_secret_v1__sampleapp__catalog-db.tf`
- `kubernetes_secret_v1__sampleapp__orders-db.tf`
- `kubernetes_secret_v1__sampleapp__orders-rabbitmq.tf`

### Service Accounts (6 files)
- `kubernetes_service_account_v1__sampleapp__ui.tf`
- `kubernetes_service_account_v1__sampleapp__assets.tf`
- `kubernetes_service_account_v1__sampleapp__catalog.tf`
- `kubernetes_service_account_v1__sampleapp__carts.tf`
- `kubernetes_service_account_v1__sampleapp__orders.tf`
- `kubernetes_service_account_v1__sampleapp__checkout.tf`

---

## Key Features

### 1. Security Best Practices

**Container Security**:
- Read-only root filesystem
- Non-root users (UID 1000)
- Dropped capabilities (ALL)
- Added only necessary capabilities (NET_BIND_SERVICE)
- No privilege escalation

**Network Security**:
- Services isolated in dedicated namespace
- ClusterIP for internal services
- LoadBalancer only for UI (internet-facing)
- Network policies can be applied

**Secrets Management**:
- Database credentials in Kubernetes Secrets
- IRSA for AWS service access (no credentials in code)
- Service accounts with least privilege

### 2. Observability

**Prometheus Integration**:
- Metrics endpoints on all services
- Annotations for Prometheus scraping
- Path: `/actuator/prometheus`
- Port: 8080

**Health Checks**:
- Liveness probes for all services
- Readiness probes for traffic management
- Graceful shutdown (30s termination grace period)

**Logging**:
- Stdout/stderr to CloudWatch (via Observability add-on)
- Structured logging
- Request tracing

### 3. Resource Management

**Resource Requests**:
- CPU: 128m-256m per service
- Memory: 128Mi-512Mi per service
- Ensures proper scheduling

**Resource Limits**:
- Memory limits prevent OOM
- CPU limits prevent noisy neighbors

**Storage**:
- Persistent volumes for databases (30Gi each)
- Ephemeral volumes for temporary data
- Retention policy: Retain on delete

### 4. High Availability

**Deployment Strategy**:
- RollingUpdate for zero-downtime deployments
- Max surge: 25%
- Max unavailable: 1

**Database Persistence**:
- StatefulSets for stable identities
- Persistent volumes for data durability
- Ordered deployment and scaling

**Load Balancing**:
- Network Load Balancer for UI
- Service load balancing for internal traffic
- Session affinity where needed

---

## Deployment Flow

### Resource Creation Order

1. **Namespace**: `sampleapp`
2. **Secrets**: Database credentials
3. **ConfigMaps**: Service configuration
4. **Service Accounts**: IRSA-enabled accounts
5. **StatefulSets**: Databases (MySQL, PostgreSQL, RabbitMQ)
6. **Services**: Network access for all components
7. **Deployments**: Application services
8. **LoadBalancer**: UI service (creates NLB)

### Dependencies

```
Namespace
    ↓
Secrets + ConfigMaps + Service Accounts
    ↓
StatefulSets (Databases)
    ↓
Services
    ↓
Deployments (Applications)
    ↓
LoadBalancer (UI)
```

---

## Accessing the Application

### Get LoadBalancer URL

```bash
# Get the LoadBalancer DNS name
kubectl get svc -n sampleapp ui

# Output example:
# NAME   TYPE           CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)        AGE
# ui     LoadBalancer   172.20.34.142   k8s-sampleap-ui-abc123-xyz789.elb.us-east-1.amazonaws.com              80:31139/TCP   5m
```

### Access the Application

```bash
# Get the URL
export UI_URL=$(kubectl get svc -n sampleapp ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Open in browser
echo "http://$UI_URL"

# Or use curl
curl http://$UI_URL
```

### Application Features

- **Home Page**: Product catalog
- **Product Details**: Click on products
- **Shopping Cart**: Add items to cart
- **Checkout**: Complete purchase
- **Orders**: View order history

---

## Testing and Verification

### After Deployment

```bash
# Verify namespace
kubectl get namespace sampleapp

# Check all resources
kubectl get all -n sampleapp

# Verify deployments
kubectl get deployments -n sampleapp
kubectl rollout status deployment/ui -n sampleapp

# Verify statefulsets
kubectl get statefulsets -n sampleapp
kubectl get pvc -n sampleapp

# Check pods
kubectl get pods -n sampleapp
kubectl get pods -n sampleapp -o wide

# Verify services
kubectl get svc -n sampleapp

# Check secrets and configmaps
kubectl get secrets -n sampleapp
kubectl get configmaps -n sampleapp

# View logs
kubectl logs -n sampleapp -l app.kubernetes.io/name=ui
kubectl logs -n sampleapp -l app.kubernetes.io/name=catalog

# Check service accounts
kubectl get sa -n sampleapp

# Test internal connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n sampleapp -- sh
# Inside pod:
curl http://catalog:8080/health
curl http://carts:8080/health
```

---

## Common Issues

### Issue: Pods stuck in Pending
**Causes**:
- Insufficient node capacity
- PVC not binding
- Image pull errors

**Solutions**:
```bash
# Check pod events
kubectl describe pod <pod-name> -n sampleapp

# Check node capacity
kubectl top nodes

# Scale inflate to trigger node provisioning
kubectl scale deployment inflate --replicas=3

# Check PVC status
kubectl get pvc -n sampleapp
kubectl describe pvc <pvc-name> -n sampleapp
```

### Issue: Database pods not starting
**Causes**:
- PVC not binding
- Secrets not found
- Resource constraints

**Solutions**:
```bash
# Check StatefulSet status
kubectl get statefulsets -n sampleapp
kubectl describe statefulset catalog-mysql -n sampleapp

# Check PVC
kubectl get pvc -n sampleapp
kubectl describe pvc data-catalog-mysql-0 -n sampleapp

# Check secrets
kubectl get secret catalog-db -n sampleapp
```

### Issue: LoadBalancer not provisioning
**Causes**:
- Auto Mode load balancer controller not ready
- Subnet tags missing
- Security group issues

**Solutions**:
```bash
# Check service status
kubectl describe svc ui -n sampleapp

# Check events
kubectl get events -n sampleapp --sort-by='.lastTimestamp'

# Verify subnet tags
aws ec2 describe-subnets --filters "Name=tag:kubernetes.io/role/elb,Values=1"

# Check Auto Mode status
kubectl get pods -n kube-system
```

### Issue: Services can't communicate
**Causes**:
- Network policies blocking traffic
- Service endpoints not ready
- DNS resolution issues

**Solutions**:
```bash
# Check service endpoints
kubectl get endpoints -n sampleapp

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -n sampleapp -- nslookup catalog

# Check network policies
kubectl get networkpolicies -n sampleapp

# Test connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n sampleapp -- curl http://catalog:8080/health
```

---

## Scaling the Application

### Scale Deployments

```bash
# Scale UI for more traffic
kubectl scale deployment ui -n sampleapp --replicas=3

# Scale catalog service
kubectl scale deployment catalog -n sampleapp --replicas=2

# Scale all services
kubectl scale deployment --all -n sampleapp --replicas=2
```

### Horizontal Pod Autoscaler

```bash
# Create HPA for UI
kubectl autoscale deployment ui -n sampleapp --cpu-percent=80 --min=2 --max=10

# Check HPA status
kubectl get hpa -n sampleapp

# View HPA details
kubectl describe hpa ui -n sampleapp
```

### Database Scaling

**Note**: StatefulSets require careful scaling:
```bash
# Scale StatefulSet (adds replicas)
kubectl scale statefulset catalog-mysql -n sampleapp --replicas=3

# Note: Database replication must be configured in the application
# This example uses single-instance databases
```

---

## Monitoring and Observability

### Prometheus Metrics

All services expose Prometheus metrics:
```bash
# Port-forward to UI service
kubectl port-forward -n sampleapp svc/ui 8080:80

# Access metrics
curl http://localhost:8080/actuator/prometheus
```

### CloudWatch Integration

Metrics and logs are automatically sent to CloudWatch:
```bash
# View logs in CloudWatch
aws logs tail /aws/eks/eks-workshop/cluster --follow

# View Container Insights
# Navigate to CloudWatch Console → Container Insights
```

### Application Performance

```bash
# Check resource usage
kubectl top pods -n sampleapp

# Check node placement
kubectl get pods -n sampleapp -o wide

# View pod resource requests/limits
kubectl describe pod <pod-name> -n sampleapp | grep -A 5 "Requests\|Limits"
```

---

## Cleanup

### Delete Application

```bash
# Delete all resources in namespace
kubectl delete namespace sampleapp

# Or use Terraform
cd sampleapp
terraform destroy
```

### Verify Cleanup

```bash
# Check namespace is gone
kubectl get namespace sampleapp

# Check PVCs are deleted
kubectl get pvc -n sampleapp

# Check LoadBalancer is deleted
aws elbv2 describe-load-balancers | grep sampleapp
```

---

## Cost Considerations

### Compute Costs
- **Pods**: ~10 pods total
- **CPU**: ~1.5 vCPUs total requested
- **Memory**: ~3.5Gi total requested
- **Nodes**: Triggers 1-2 nodes via Karpenter

### Storage Costs
- **PVCs**: 3 × 30Gi = 90Gi total
- **EBS gp3**: ~$7.20/month (90Gi × $0.08/GB/month)

### Network Costs
- **NLB**: ~$16/month base + data transfer
- **Data Transfer**: $0.01/GB (first 10TB)

### Total Estimated Cost
- **Compute**: ~$30-60/month (depends on node types)
- **Storage**: ~$7/month
- **Network**: ~$20/month
- **Total**: ~$57-87/month

---

## Security Considerations

### Container Security
✅ Read-only root filesystem  
✅ Non-root users  
✅ Dropped capabilities  
✅ No privilege escalation  
✅ Security contexts enforced

### Network Security
✅ Namespace isolation  
✅ ClusterIP for internal services  
✅ LoadBalancer only for UI  
✅ Can add network policies

### Secrets Management
✅ Kubernetes Secrets for credentials  
✅ IRSA for AWS access  
✅ No hardcoded credentials  
✅ Can integrate with External Secrets

### Database Security
✅ Persistent storage  
✅ Credentials in Secrets  
✅ Internal-only access  
✅ Can enable encryption at rest

---

## Best Practices

### DO:
✅ Use resource requests and limits  
✅ Implement health checks  
✅ Use read-only root filesystem  
✅ Run as non-root user  
✅ Use IRSA for AWS access  
✅ Monitor application metrics  
✅ Use persistent storage for databases  
✅ Implement graceful shutdown

### DON'T:
❌ Run containers as root  
❌ Use privileged containers  
❌ Hardcode credentials  
❌ Skip health checks  
❌ Ignore resource limits  
❌ Use ephemeral storage for databases  
❌ Expose databases publicly  
❌ Skip monitoring and logging

---

## Related Documentation

- **addons Stage**: See `docs/README-addons.md` for add-ons configuration
- **nodepool Stage**: See `docs/README-nodepool.md` for node provisioning
- **cluster Stage**: See `docs/README-cluster.md` for EKS cluster setup
- **AWS Retail Store Sample**: https://github.com/aws-containers/retail-store-sample-app

---

## Summary

The sampleapp stage deploys a complete microservices e-commerce application with:
- **6 microservices**: UI, Assets, Catalog, Carts, Orders, Checkout
- **3 databases**: MySQL, PostgreSQL, RabbitMQ (StatefulSets)
- **1 cache**: Redis (Deployment)
- **Security**: Non-root containers, read-only filesystems, IRSA
- **Observability**: Prometheus metrics, health checks, CloudWatch logs
- **High Availability**: RollingUpdate strategy, persistent storage
- **Internet Access**: LoadBalancer for UI service

This application demonstrates production-ready Kubernetes patterns including microservices architecture, database persistence, message queuing, caching, and secure container practices.
