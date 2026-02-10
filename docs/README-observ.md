# observ Stage Documentation

## Overview

The `observ` stage deploys a comprehensive observability solution for the EKS cluster using the AWS Observability Accelerator. This stage sets up Amazon Managed Prometheus, Amazon Managed Grafana, OpenTelemetry, and pre-configured dashboards for monitoring cluster health, application performance, and infrastructure metrics.

**Execution Time**: ~10-15 minutes (part of the ~40 minute total build)  
**Dependencies**: tf-setup, net, cluster, nodepool, addons (requires running cluster)  
**Outputs**: Grafana workspace, Prometheus workspace, dashboards, alerts  
**Purpose**: Complete observability stack for EKS

---

## Architecture Overview

### Observability Stack

```
┌─────────────────────────────────────────────────────────────────┐
│ EKS Cluster                                                      │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ AWS Distro for OpenTelemetry (ADOT)                    │    │
│  │ - Collector DaemonSet                                  │    │
│  │ - Operator for custom resources                        │    │
│  │ - Metrics, logs, traces collection                     │    │
│  └────────────────┬───────────────────────────────────────┘    │
│                   │                                              │
│  ┌────────────────▼───────────────────────────────────────┐    │
│  │ Prometheus Server                                       │    │
│  │ - Scrapes metrics from pods                            │    │
│  │ - Stores locally (short-term)                          │    │
│  │ - Remote writes to AMP                                 │    │
│  └────────────────┬───────────────────────────────────────┘    │
│                   │                                              │
│  ┌────────────────▼───────────────────────────────────────┐    │
│  │ Cert Manager                                            │    │
│  │ - TLS certificates for webhooks                        │    │
│  │ - Required for ADOT operator                           │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ External Secrets Operator                                │  │
│  │ - Syncs Grafana API key from Secrets Manager           │  │
│  │ - Creates Kubernetes secret for dashboards             │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────┬─────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ AWS Managed Services                                             │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ Amazon Managed Prometheus (AMP)                        │    │
│  │ - Long-term metrics storage                            │    │
│  │ - PromQL query engine                                  │    │
│  │ - Alert Manager                                        │    │
│  │ - Workspace: amp-demo                                  │    │
│  └────────────────┬───────────────────────────────────────┘    │
│                   │                                              │
│  ┌────────────────▼───────────────────────────────────────┐    │
│  │ Amazon Managed Grafana (AMG)                           │    │
│  │ - Visualization and dashboards                         │    │
│  │ - SAML authentication                                  │    │
│  │ - Pre-configured dashboards                            │    │
│  │ - Workspace: keycloak-blog                             │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ AWS X-Ray                                                │  │
│  │ - Distributed tracing                                   │  │
│  │ - Service maps                                          │  │
│  │ - Performance insights                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ CloudWatch                                               │  │
│  │ - Logs aggregation                                      │  │
│  │ - Additional metrics                                    │  │
│  │ - Alarms and notifications                              │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Key Components

### 1. AWS Observability Accelerator Module
**Purpose**: Opinionated, production-ready observability stack

**Source**: `github.com/aws-observability/terraform-aws-observability-accelerator`

**Features**:
- Pre-configured Prometheus and Grafana
- ADOT operator and collectors
- Pre-built dashboards
- Alert rules
- Best practices configuration

### 2. Amazon Managed Prometheus (AMP)
**Purpose**: Fully managed Prometheus-compatible monitoring service

**Configuration**:
- **Workspace**: Automatically created
- **Scrape Interval**: 60 seconds
- **Scrape Timeout**: 15 seconds
- **Alert Manager**: Enabled
- **Retention**: 150 days (default)

**Benefits**:
- No infrastructure to manage
- Automatic scaling
- High availability
- Long-term storage
- PromQL compatibility

### 3. Amazon Managed Grafana (AMG)
**Purpose**: Fully managed Grafana service for visualization

**Configuration**:
- **Workspace Name**: `keycloak-blog`
- **Authentication**: SAML (Keycloak integration)
- **Permission Type**: Customer managed
- **Account Access**: Current account only

**IAM Permissions**:
- `AmazonPrometheusQueryAccess` - Query AMP
- `AmazonGrafanaCloudWatchAccess` - CloudWatch data source
- `AWSXrayReadOnlyAccess` - X-Ray tracing data

**API Key**:
- **Name**: `observability-key`
- **Role**: ADMIN
- **TTL**: 5 days (432000 seconds)
- **Purpose**: Dashboard provisioning

### 4. AWS Distro for OpenTelemetry (ADOT)
**Purpose**: Collect and export telemetry data

**Components**:
- **Operator**: Manages ADOT collectors
- **Collector**: DaemonSet on each node
- **Exporters**: Prometheus, X-Ray, CloudWatch

**Telemetry Types**:
- **Metrics**: CPU, memory, network, custom
- **Logs**: Container logs, application logs
- **Traces**: Distributed tracing with X-Ray

### 5. Cert Manager
**Purpose**: TLS certificate management

**Configuration**:
- **Enabled**: true
- **Purpose**: ADOT operator webhooks
- **Certificates**: Self-signed for internal use

**Why Needed?**
- ADOT operator uses admission webhooks
- Webhooks require TLS certificates
- Cert Manager automates certificate lifecycle

### 6. External Secrets Operator
**Purpose**: Sync Grafana API key to Kubernetes

**Configuration**:
- **Enabled**: true
- **Secret Name**: `grafana-admin-credentials`
- **Namespace**: `grafana-operator`
- **Source**: AWS Secrets Manager

**Why Needed?**
- Grafana API key stored securely in AWS
- Synced to Kubernetes for dashboard provisioning
- Automatic rotation support

---

## File-by-File Breakdown

### Provider Configuration

#### main.tf
**Purpose**: Configures providers and deploys observability stack

**Kubernetes Provider**:
```terraform
provider "kubernetes" {
  host                   = data.aws_ssm_parameter.endpoint.value
  cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
  config_path = "~/.kube/config"
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
  }
}
```

**Helm Provider**:
```terraform
provider "helm" {
  kubernetes {
    host                   = data.aws_ssm_parameter.endpoint.value
    cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
    }
  }
}
```

**EKS Monitoring Module**:
```terraform
module "eks_monitoring" {
  source = "github.com/aws-observability/terraform-aws-observability-accelerator//modules/eks-monitoring"
  
  eks_cluster_id = data.aws_ssm_parameter.cluster-name.value
  
  # Core components
  enable_amazon_eks_adot = true
  enable_cert_manager = true
  enable_external_secrets = true
  
  # Grafana integration
  grafana_api_key = aws_grafana_workspace_api_key.key.key
  grafana_url = format("https://%s", aws_grafana_workspace.workshop.endpoint)
  target_secret_name = "grafana-admin-credentials"
  target_secret_namespace = "grafana-operator"
  
  # Prometheus
  enable_managed_prometheus = true
  enable_alertmanager = true
  prometheus_config = {
    global_scrape_interval = "60s"
    global_scrape_timeout = "15s"
  }
  
  # Monitoring features
  enable_apiserver_monitoring = true
  enable_dashboards = true
  enable_logs = true
  enable_tracing = true
}
```

**Key Features Enabled**:
- **ADOT**: OpenTelemetry collection
- **Cert Manager**: TLS certificates
- **External Secrets**: Grafana API key sync
- **Managed Prometheus**: Metrics storage
- **Alert Manager**: Alert routing
- **API Server Monitoring**: Control plane metrics
- **Dashboards**: Pre-built Grafana dashboards
- **Logs**: Log collection and forwarding
- **Tracing**: Distributed tracing with X-Ray

---

### Grafana Workspace

#### grafana.tf
**Purpose**: Creates Amazon Managed Grafana workspace and IAM role

**Grafana Workspace**:
```terraform
resource "aws_grafana_workspace" "workshop" {
  account_access_type = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML"]
  permission_type = "CUSTOMER_MANAGED"
  role_arn = aws_iam_role.grafana.arn
  name = "keycloak-blog"
}
```

**Configuration**:
- **Account Access**: Current AWS account only
- **Authentication**: SAML (Keycloak)
- **Permissions**: Customer managed (custom IAM role)
- **Name**: `keycloak-blog` (matches Keycloak configuration)

**IAM Role**:
```terraform
resource "aws_iam_role" "grafana" {
  name = "grafana-assume"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "grafana.amazonaws.com"
      }
    }]
  })
}
```

**Attached Policies**:
1. **AmazonPrometheusQueryAccess**: Query AMP workspaces
2. **AmazonGrafanaCloudWatchAccess**: CloudWatch data source
3. **AWSXrayReadOnlyAccess**: X-Ray tracing data

**Why These Policies?**
- Grafana needs to query multiple AWS data sources
- Least privilege access to each service
- Read-only access (no write permissions)

---

### Grafana API Key

#### grafana-key.tf
**Purpose**: Creates API key for dashboard provisioning

```terraform
resource "aws_grafana_workspace_api_key" "key" {
  key_name = "observability-key"
  key_role = "ADMIN"
  seconds_to_live = 432000  # 5 days
  workspace_id = aws_grafana_workspace.workshop.id
}
```

**Configuration**:
- **Name**: `observability-key`
- **Role**: ADMIN (full permissions)
- **TTL**: 5 days (432000 seconds)
- **Purpose**: Automated dashboard provisioning

**Why ADMIN Role?**
- Required for creating/updating dashboards
- Needed for data source configuration
- Used by Observability Accelerator

**Security Considerations**:
- Short TTL (5 days)
- Stored in AWS Secrets Manager
- Synced to Kubernetes via External Secrets
- Rotated regularly

---

## Symlinked Files

These files are symlinked from `common-files/`:

- **aws-data.tf**: AWS account and region data sources
- **backend-observ.tf**: S3 backend configuration (generated by tf-setup)
- **data-params-setup.tf**: Setup stage SSM parameters
- **data-params-cluster.tf**: Cluster stage SSM parameters (endpoint, OIDC, etc.)
- **vars-main.tf**: Common variables

---

## Pre-Configured Dashboards

The Observability Accelerator automatically provisions these dashboards:

### Cluster Dashboards
1. **Cluster Overview**: High-level cluster health
2. **Node Metrics**: CPU, memory, disk, network per node
3. **Pod Metrics**: Resource usage per pod
4. **Namespace Metrics**: Resource usage per namespace

### Workload Dashboards
5. **Deployment Metrics**: Deployment health and performance
6. **StatefulSet Metrics**: StatefulSet health and performance
7. **DaemonSet Metrics**: DaemonSet health and performance

### Infrastructure Dashboards
8. **API Server**: Control plane performance
9. **etcd**: etcd cluster health
10. **CoreDNS**: DNS query metrics
11. **Kubelet**: Kubelet performance

### Application Dashboards
12. **Java/JVM**: Java application metrics
13. **NGINX**: NGINX ingress metrics
14. **Custom**: Application-specific metrics

---

## Metrics Collected

### Cluster Metrics
- Node CPU, memory, disk, network
- Pod CPU, memory, network
- Container resource usage
- Persistent volume usage

### Kubernetes Metrics
- API server requests and latency
- Scheduler performance
- Controller manager metrics
- etcd performance

### Application Metrics
- HTTP request rate and latency
- Error rates
- Custom application metrics (Prometheus format)
- JVM metrics (for Java apps)

### Infrastructure Metrics
- Load balancer metrics
- VPC flow logs
- CloudWatch metrics

---

## Accessing Grafana

### Get Grafana URL

```bash
# Get workspace endpoint
aws grafana describe-workspace --workspace-id <workspace-id> --query 'workspace.endpoint' --output text

# Or from Terraform output
terraform output -raw grafana_endpoint
```

### Login to Grafana

1. Navigate to Grafana URL
2. Click "Sign in with SAML"
3. Authenticate with Keycloak
4. Access dashboards

### Default Dashboards Location

- Navigate to "Dashboards" in left menu
- Look for "AWS Observability Accelerator" folder
- Pre-configured dashboards are organized by category

---

## Querying Metrics

### PromQL Examples

```promql
# Node CPU usage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Pod memory usage
sum(container_memory_working_set_bytes{pod=~".*"}) by (pod)

# HTTP request rate
rate(http_requests_total[5m])

# API server latency
histogram_quantile(0.99, sum(rate(apiserver_request_duration_seconds_bucket[5m])) by (le))

# Pod restart count
kube_pod_container_status_restarts_total
```

### CloudWatch Logs Insights

```sql
# Container logs
fields @timestamp, @message
| filter kubernetes.namespace_name = "sampleapp"
| sort @timestamp desc
| limit 100

# Error logs
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
```

---

## Alerting

### Alert Manager Configuration

The Observability Accelerator sets up Alert Manager with:
- **Workspace-level**: Alerts managed in AMP
- **Routing**: Alert routing rules
- **Receivers**: Notification channels (SNS, email, etc.)

### Example Alert Rules

```yaml
# High CPU usage
- alert: HighCPUUsage
  expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High CPU usage on {{ $labels.instance }}"

# Pod restart
- alert: PodRestarting
  expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Pod {{ $labels.pod }} is restarting"

# API server errors
- alert: APIServerErrors
  expr: rate(apiserver_request_total{code=~"5.."}[5m]) > 0.01
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "API server returning 5xx errors"
```

---

## Testing and Verification

### After Deployment

```bash
# Verify Grafana workspace
aws grafana list-workspaces
aws grafana describe-workspace --workspace-id <workspace-id>

# Verify Prometheus workspace
aws amp list-workspaces
aws amp describe-workspace --workspace-id <workspace-id>

# Check ADOT operator
kubectl get pods -n opentelemetry-operator-system

# Check ADOT collector
kubectl get pods -n adot-collector

# Check Cert Manager
kubectl get pods -n cert-manager

# Check External Secrets
kubectl get pods -n external-secrets

# Verify Prometheus server
kubectl get pods -n prometheus

# Check Grafana secret
kubectl get secret grafana-admin-credentials -n grafana-operator

# Test Prometheus query
aws amp query-workspace --workspace-id <workspace-id> --query-string "up"

# Check dashboards in Grafana
# Navigate to Grafana URL and verify dashboards are present
```

---

## Common Issues

### Issue: Grafana workspace creation fails
**Causes**:
- IAM role permissions missing
- SAML configuration incomplete
- Workspace name conflict

**Solutions**:
```bash
# Check IAM role
aws iam get-role --role-name grafana-assume

# Verify policies attached
aws iam list-attached-role-policies --role-name grafana-assume

# Check workspace status
aws grafana describe-workspace --workspace-id <workspace-id>
```

### Issue: Dashboards not appearing
**Causes**:
- API key expired
- External Secrets not syncing
- Grafana API key permissions insufficient

**Solutions**:
```bash
# Check API key
aws grafana describe-workspace-api-key --key-id <key-id> --workspace-id <workspace-id>

# Verify External Secrets
kubectl get externalsecret -n grafana-operator
kubectl describe externalsecret -n grafana-operator

# Check secret
kubectl get secret grafana-admin-credentials -n grafana-operator -o yaml
```

### Issue: ADOT collector not collecting metrics
**Causes**:
- Cert Manager not ready
- ADOT operator not running
- Prometheus server not configured

**Solutions**:
```bash
# Check Cert Manager
kubectl get pods -n cert-manager
kubectl get certificates -A

# Check ADOT operator
kubectl logs -n opentelemetry-operator-system -l app.kubernetes.io/name=opentelemetry-operator

# Check ADOT collector
kubectl get pods -n adot-collector
kubectl logs -n adot-collector -l app.kubernetes.io/name=adot-collector

# Verify Prometheus config
kubectl get configmap -n prometheus
```

### Issue: Prometheus remote write failing
**Causes**:
- AMP workspace not ready
- IAM permissions missing
- Network connectivity issues

**Solutions**:
```bash
# Check AMP workspace
aws amp describe-workspace --workspace-id <workspace-id>

# Check Prometheus logs
kubectl logs -n prometheus -l app.kubernetes.io/name=prometheus

# Verify IRSA
kubectl get sa -n prometheus -o yaml
# Look for eks.amazonaws.com/role-arn annotation
```

---

## Cost Considerations

### Amazon Managed Prometheus
- **Metrics Ingested**: $0.30 per 10M samples
- **Metrics Stored**: $0.03 per GB-month
- **Query Samples**: $0.01 per 1M samples
- **Estimated**: ~$50-100/month for typical cluster

### Amazon Managed Grafana
- **Workspace**: $9 per active user per month
- **Editor License**: Included
- **Viewer**: Free
- **Estimated**: ~$9-45/month (1-5 users)

### AWS X-Ray
- **Traces Recorded**: $5 per 1M traces
- **Traces Retrieved**: $0.50 per 1M traces
- **Estimated**: ~$10-20/month

### CloudWatch
- **Logs Ingested**: $0.50 per GB
- **Logs Stored**: $0.03 per GB-month
- **Metrics**: $0.30 per metric per month
- **Estimated**: ~$20-50/month

### Total Estimated Cost
**Monthly**: ~$89-215/month depending on usage

---

## Security Considerations

### IAM Roles
✅ Least privilege access  
✅ Service-specific roles  
✅ No long-lived credentials  
✅ IRSA for pod-level permissions

### API Keys
✅ Short TTL (5 days)  
✅ Stored in Secrets Manager  
✅ Synced via External Secrets  
✅ Rotated regularly

### Network Security
✅ Private endpoints for AMP/AMG  
✅ TLS for all communications  
✅ VPC endpoints for AWS services  
✅ No public exposure

### Data Security
✅ Encryption at rest (AMP, AMG)  
✅ Encryption in transit (TLS)  
✅ Access logging enabled  
✅ Audit trails in CloudTrail

---

## Best Practices

### DO:
✅ Use managed services (AMP, AMG) for production  
✅ Enable Alert Manager for notifications  
✅ Set up retention policies  
✅ Use SAML authentication for Grafana  
✅ Monitor the monitoring stack itself  
✅ Set up dashboards for key metrics  
✅ Configure alerts for critical issues  
✅ Regularly review and update dashboards

### DON'T:
❌ Use long-lived API keys  
❌ Grant excessive IAM permissions  
❌ Ignore alert fatigue  
❌ Skip retention policies  
❌ Expose Grafana publicly without auth  
❌ Collect unnecessary metrics  
❌ Ignore cost optimization  
❌ Skip regular reviews of alerts

---

## Related Documentation

- **addons Stage**: See `docs/README-addons.md` for add-ons configuration
- **cluster Stage**: See `docs/README-cluster.md` for EKS cluster setup
- **AWS Observability Accelerator**: https://aws-observability.github.io/terraform-aws-observability-accelerator/
- **Amazon Managed Prometheus**: https://docs.aws.amazon.com/prometheus/
- **Amazon Managed Grafana**: https://docs.aws.amazon.com/grafana/
- **ADOT**: https://aws-otel.github.io/

---

## Summary

The observ stage deploys a complete observability solution with:
- **Amazon Managed Prometheus**: Metrics storage and querying
- **Amazon Managed Grafana**: Visualization and dashboards
- **ADOT**: OpenTelemetry collection (metrics, logs, traces)
- **Cert Manager**: TLS certificate management
- **External Secrets**: Secure API key management
- **Pre-built Dashboards**: Cluster, workload, and application monitoring
- **Alert Manager**: Alert routing and notifications
- **X-Ray Integration**: Distributed tracing
- **CloudWatch Integration**: Logs and additional metrics

This configuration provides production-ready observability for EKS clusters with minimal operational overhead, leveraging AWS managed services for scalability, reliability, and security.
