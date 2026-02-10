# addons Stage Documentation

## Overview

The `addons` stage installs essential Kubernetes add-ons and AWS integrations for the EKS cluster using the EKS Blueprints Addons module. This stage configures observability, DNS management, secrets management, and metrics collection.

**Execution Time**: ~5-10 minutes (part of the ~40 minute total build)  
**Dependencies**: tf-setup, net, cluster, nodepool (requires running cluster with nodes)  
**Outputs**: Installed add-ons, IRSA roles, Helm releases  
**Next Stage**: observ or sampleapp (application deployments)

---

## Architecture Overview

### Add-ons Ecosystem

```
┌─────────────────────────────────────────────────────────────────┐
│ EKS Cluster                                                      │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ AWS EKS Add-ons (Managed by AWS)                       │    │
│  │ - CloudWatch Observability                             │    │
│  │ - Metrics Server                                       │    │
│  │ - Network Flow Monitoring Agent                        │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ EKS Blueprints Add-ons (Helm Charts)                   │    │
│  │                                                         │    │
│  │  External DNS (external-dns namespace)                 │    │
│  │  ├─ Service Account with IRSA                          │    │
│  │  ├─ IAM Role for Route53 access                        │    │
│  │  └─ Watches Services/Ingresses for DNS records         │    │
│  │                                                         │    │
│  │  External Secrets (external-secrets namespace)         │    │
│  │  ├─ Operator for syncing secrets                       │    │
│  │  ├─ Supports AWS Secrets Manager, Parameter Store      │    │
│  │  └─ Creates Kubernetes secrets from AWS sources        │    │
│  │                                                         │    │
│  │  CloudWatch Metrics (cw-metrics namespace)             │    │
│  │  ├─ Collects cluster metrics                           │    │
│  │  └─ Sends to CloudWatch                                │    │
│  └────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ AWS Services                                                     │
│ - Route53 (DNS records)                                         │
│ - CloudWatch (metrics, logs, observability)                     │
│ - Secrets Manager (application secrets)                         │
│ - Systems Manager Parameter Store (configuration)               │
└──────────────────────────────────────────────────────────────────┘
```

---

## Key Features

### 1. AWS EKS Add-ons (Managed)
- **CloudWatch Observability**: Container Insights, application signals
- **Metrics Server**: Resource metrics for HPA and kubectl top
- **Network Flow Monitoring**: VPC flow logs for network analysis

### 2. External DNS
- **Purpose**: Automatic DNS record management
- **Integration**: Route53 private hosted zone
- **IRSA**: IAM role for Route53 permissions
- **Use Case**: Automatic DNS for Services and Ingresses

### 3. External Secrets
- **Purpose**: Sync secrets from AWS to Kubernetes
- **Sources**: Secrets Manager, Parameter Store
- **Operator**: Watches ExternalSecret CRDs
- **Use Case**: Centralized secret management

### 4. CloudWatch Metrics
- **Purpose**: Cluster and pod metrics collection
- **Destination**: CloudWatch
- **Use Case**: Monitoring, alerting, dashboards

---

## File-by-File Breakdown

### Provider Configuration

#### main.tf
**Purpose**: Configures Kubernetes, Helm, and kubectl providers for cluster interaction

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

**Configuration**:
- **Host**: Cluster API endpoint from SSM
- **CA Certificate**: Base64-decoded cluster CA
- **Config Path**: Local kubeconfig file
- **Authentication**: AWS EKS token via AWS CLI

**Why exec authentication?**
- Uses AWS IAM for authentication
- Tokens are short-lived (15 minutes)
- Automatically refreshed by AWS CLI
- No long-lived credentials in Terraform state

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

**Purpose**: Install Helm charts (External DNS, External Secrets, etc.)

**kubectl Provider**:
```terraform
provider "kubectl" {
  apply_retry_count      = 5
  host                   = data.aws_ssm_parameter.endpoint.value
  cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", data.aws_ssm_parameter.cluster-name.value]
  }
}
```

**Features**:
- **Retry Count**: 5 retries for transient failures
- **Load Config**: Disabled (uses exec auth)
- **Purpose**: Apply raw Kubernetes manifests

---

### EKS Blueprints Add-ons Module

#### main.tf (continued)
**Purpose**: Installs and configures add-ons using the EKS Blueprints Addons module

**Module Configuration**:
```terraform
module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.21.0"
  
  cluster_name      = data.aws_ssm_parameter.cluster-name.value
  cluster_endpoint  = data.aws_ssm_parameter.endpoint.value
  cluster_version   = data.aws_ssm_parameter.tf-eks-version.value
  oidc_provider_arn = data.aws_ssm_parameter.oidc_provider_arn.value
}
```

**Required Parameters**:
- **cluster_name**: EKS cluster name
- **cluster_endpoint**: API server URL
- **cluster_version**: Kubernetes version
- **oidc_provider_arn**: For IRSA role creation

---

### External DNS Configuration

**Purpose**: Automatically create/update Route53 DNS records for Kubernetes resources

**Configuration**:
```terraform
enable_external_dns = true
external_dns = {
  name             = "external-dns"
  namespace        = "external-dns"
  service_account  = "external-dns"
  create_namespace = true
  depends_on       = [null_resource.sleep]
}
external_dns_route53_zone_arns = [data.aws_route53_zone.phz.arn]
```

**Features**:
- **Namespace**: Dedicated `external-dns` namespace
- **Service Account**: With IRSA annotation
- **Route53 Zone**: Private hosted zone from net stage
- **Dependency**: Waits for load balancer controller

**How It Works**:
1. Watches Kubernetes Services and Ingresses
2. Detects annotations like `external-dns.alpha.kubernetes.io/hostname`
3. Creates/updates Route53 DNS records
4. Deletes records when resources are removed

**Example Usage**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  annotations:
    external-dns.alpha.kubernetes.io/hostname: my-app.example.com
spec:
  type: LoadBalancer
  ports:
    - port: 80
  selector:
    app: my-app
```

**IRSA Role**:
- Automatically created by Blueprints module
- Permissions: Route53 read/write for specified zones
- Attached to `external-dns` service account

---

### External Secrets Configuration

**Purpose**: Sync secrets from AWS Secrets Manager/Parameter Store to Kubernetes

**Configuration**:
```terraform
external_secrets = {
  name             = "external-secrets"
  chart_version    = "0.14.2"
  repository       = "https://charts.external-secrets.io"
  namespace        = "external-secrets"
  create_namespace = true
}
```

**Features**:
- **Operator**: Watches ExternalSecret CRDs
- **Sources**: AWS Secrets Manager, Parameter Store, S3
- **Sync**: Automatic synchronization to Kubernetes secrets
- **Refresh**: Periodic refresh of secret values

**How It Works**:
1. Create ExternalSecret CRD pointing to AWS secret
2. Operator fetches secret from AWS
3. Creates/updates Kubernetes Secret
4. Refreshes on schedule or webhook

**Example Usage**:
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: my-app-secret
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: my-app/password
```

**IRSA Role**:
- Requires IAM role with Secrets Manager/SSM permissions
- Not automatically created (must be configured separately)
- Attached to service account in application namespace

---

### CloudWatch Metrics Configuration

**Purpose**: Collect and send cluster metrics to CloudWatch

**Configuration**:
```terraform
aws_cloudwatch_metrics = {
  namespace        = "cw-metrics"
  create_namespace = true
}
```

**Features**:
- **Metrics**: CPU, memory, network, disk
- **Destination**: CloudWatch Metrics
- **Namespace**: `cw-metrics`
- **Use Case**: Monitoring, alerting, dashboards

**Metrics Collected**:
- Node CPU/memory utilization
- Pod CPU/memory utilization
- Network traffic
- Disk I/O
- Container metrics

---

### Commented/Disabled Add-ons

The module includes many commented-out add-ons for reference:

#### Cert Manager
```terraform
enable_cert_manager = false
```
- **Purpose**: TLS certificate management
- **Integration**: Let's Encrypt, AWS Private CA
- **Status**: Disabled (can be enabled in observability stage)

#### AWS Load Balancer Controller
```terraform
# Commented out - Auto Mode handles load balancing
```
- **Purpose**: Provision ALB/NLB for Ingresses
- **Status**: Not needed with Auto Mode
- **Auto Mode**: Automatically manages load balancers

#### Fluent Bit
```terraform
# Commented out - CloudWatch Observability handles logging
```
- **Purpose**: Log collection and forwarding
- **Status**: Replaced by CloudWatch Observability add-on

#### AWS Private CA Issuer
```terraform
enable_aws_privateca_issuer = false
```
- **Purpose**: Issue certificates from AWS Private CA
- **Status**: Disabled (optional)

---

### AWS EKS Add-ons

#### eks-addons.tf
**Purpose**: Install AWS-managed EKS add-ons

**Add-ons Installed**:

##### CloudWatch Observability
```terraform
resource "aws_eks_addon" "cloudwatch-observability" {
  cluster_name = data.aws_ssm_parameter.cluster-name.value
  addon_name   = "amazon-cloudwatch-observability"
}
```

**Features**:
- **Container Insights**: Pod and node metrics
- **Application Signals**: Application performance monitoring
- **Log Collection**: Container logs to CloudWatch
- **Automatic**: No additional configuration needed

**What It Provides**:
- Pre-built CloudWatch dashboards
- Automatic metric collection
- Log aggregation
- Performance insights

##### Metrics Server
```terraform
resource "aws_eks_addon" "metrics-server" {
  cluster_name = data.aws_ssm_parameter.cluster-name.value
  addon_name   = "metrics-server"
}
```

**Features**:
- **Resource Metrics**: CPU and memory usage
- **HPA**: Enables Horizontal Pod Autoscaler
- **kubectl top**: Enables `kubectl top nodes/pods`
- **Required**: For cluster autoscaling

**Use Cases**:
```bash
# View node resource usage
kubectl top nodes

# View pod resource usage
kubectl top pods -A

# HPA based on CPU
kubectl autoscale deployment my-app --cpu-percent=80 --min=2 --max=10
```

##### Network Flow Monitoring Agent
```terraform
resource "aws_eks_addon" "network-flow-monitoring-agent" {
  cluster_name = data.aws_ssm_parameter.cluster-name.value
  addon_name   = "aws-network-flow-monitoring-agent"
}
```

**Features**:
- **VPC Flow Logs**: Network traffic analysis
- **Security**: Detect anomalous traffic
- **Troubleshooting**: Network connectivity issues
- **Integration**: CloudWatch Logs

**What It Monitors**:
- Pod-to-pod traffic
- Pod-to-service traffic
- Ingress/egress traffic
- Network policies

---

### Data Sources

#### data-r53.tf
**Purpose**: Retrieve Route53 hosted zone information

```terraform
data "aws_route53_zone" "phz" {
  zone_id = data.aws_ssm_parameter.phz-id.value
}
```

**Usage**:
- Provides zone ARN for External DNS permissions
- Validates zone exists
- Used in IRSA policy

---

### Synchronization

#### null_sleep.tf
**Purpose**: Add delay between add-on installations

```terraform
resource "null_resource" "sleep" {
  triggers = {
    always_run = timestamp() 
  }
  depends_on = [module.eks_blueprints_addons.aws_load_balancer_controller]
  provisioner "local-exec" {
    command = "sleep 20"
  }
}
```

**Why Needed?**
- Allows load balancer controller to fully initialize
- Prevents race conditions
- Ensures webhooks are ready
- 20-second delay for stabilization

**Dependency Chain**:
1. Load balancer controller installed
2. Sleep 20 seconds
3. External DNS installed (depends on sleep)

---

## Symlinked Files

These files are symlinked from `common-files/`:

- **aws-data.tf**: AWS account and region data sources
- **backend-addons.tf**: S3 backend configuration (generated by tf-setup)
- **data-params-setup.tf**: Setup stage SSM parameters
- **data-params-net.tf**: Network stage SSM parameters (VPC, subnets)
- **data-params-cluster.tf**: Cluster stage SSM parameters (endpoint, OIDC, etc.)
- **vars-main.tf**: Common variables

---

## Resource Dependencies

```
cluster (EKS cluster, OIDC provider)
    ↓
nodepool (running nodes)
    ↓
addons/main.tf (provider configuration)
    ↓
addons/eks-addons.tf (AWS managed add-ons)
    ↓
module.eks_blueprints_addons
    ├─→ External DNS (with IRSA)
    ├─→ External Secrets (operator)
    ├─→ CloudWatch Metrics
    └─→ (other add-ons)
    ↓
null_resource.sleep (stabilization)
    ↓
observ/sampleapp stages
```

---

## IRSA Roles Created

The EKS Blueprints Addons module automatically creates IRSA roles:

### External DNS Role
**Permissions**:
- `route53:ChangeResourceRecordSets`
- `route53:ListResourceRecordSets`
- `route53:ListHostedZones`

**Trust Policy**:
```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/oidc.eks.REGION.amazonaws.com/id/OIDC_ID"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "oidc.eks.REGION.amazonaws.com/id/OIDC_ID:sub": "system:serviceaccount:external-dns:external-dns"
    }
  }
}
```

### CloudWatch Metrics Role
**Permissions**:
- `cloudwatch:PutMetricData`
- `ec2:DescribeVolumes`
- `ec2:DescribeTags`

---

## Testing and Verification

### After Deployment

```bash
# Verify EKS add-ons
aws eks list-addons --cluster-name eks-workshop
aws eks describe-addon --cluster-name eks-workshop --addon-name metrics-server

# Check add-on pods
kubectl get pods -n kube-system | grep metrics-server
kubectl get pods -n amazon-cloudwatch
kubectl get pods -n external-dns
kubectl get pods -n external-secrets
kubectl get pods -n cw-metrics

# Test Metrics Server
kubectl top nodes
kubectl top pods -A

# Test External DNS
kubectl get deployment -n external-dns
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns

# Test External Secrets
kubectl get pods -n external-secrets
kubectl get crd | grep external-secrets

# Verify IRSA roles
kubectl get sa -n external-dns external-dns -o yaml
# Look for eks.amazonaws.com/role-arn annotation

# Check Helm releases
helm list -A

# Verify CloudWatch Observability
kubectl get pods -n amazon-cloudwatch
kubectl logs -n amazon-cloudwatch -l app.kubernetes.io/name=cloudwatch-agent
```

---

## Common Issues

### Issue: Provider authentication failed
**Cause**: kubeconfig not configured or expired  
**Solution**:
```bash
aws eks update-kubeconfig --name eks-workshop
kubectl get nodes
```

### Issue: Metrics Server not working
**Cause**: Add-on not fully installed  
**Solution**:
```bash
# Check add-on status
aws eks describe-addon --cluster-name eks-workshop --addon-name metrics-server

# Check pod status
kubectl get pods -n kube-system -l k8s-app=metrics-server

# Check logs
kubectl logs -n kube-system -l k8s-app=metrics-server
```

### Issue: External DNS not creating records
**Causes**:
- IRSA role not configured
- Route53 zone permissions missing
- Service annotation missing

**Solutions**:
```bash
# Check External DNS logs
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns

# Verify IRSA role
kubectl get sa -n external-dns external-dns -o yaml

# Check IAM role permissions
aws iam get-role --role-name <external-dns-role>
aws iam list-attached-role-policies --role-name <external-dns-role>

# Test with sample service
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: test-dns
  annotations:
    external-dns.alpha.kubernetes.io/hostname: test.example.com
spec:
  type: LoadBalancer
  ports:
    - port: 80
  selector:
    app: test
EOF
```

### Issue: External Secrets not syncing
**Causes**:
- SecretStore not configured
- IRSA role missing
- AWS secret doesn't exist

**Solutions**:
```bash
# Check operator logs
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets

# Verify SecretStore
kubectl get secretstore -A

# Check ExternalSecret status
kubectl describe externalsecret <name>
```

### Issue: Helm chart installation timeout
**Cause**: Cluster resources insufficient  
**Solution**:
```bash
# Check node capacity
kubectl top nodes

# Scale inflate deployment to trigger node provisioning
kubectl scale deployment inflate --replicas=3

# Retry Terraform apply
terraform apply
```

---

## Extending the Configuration

### Adding Cert Manager

Uncomment in `main.tf`:
```terraform
enable_cert_manager = true
cert_manager_route53_hosted_zone_arns = [data.aws_route53_zone.phz.arn]
```

### Adding AWS Load Balancer Controller

Uncomment in `main.tf`:
```terraform
enable_aws_load_balancer_controller = true
aws_load_balancer_controller = {
  namespace = "kube-system"
  set = [
    {
      name  = "vpcId"
      value = data.aws_ssm_parameter.eks-vpc.value
    },
  ]
}
```

**Note**: Auto Mode already handles load balancing, so this is optional.

### Adding Fluent Bit for Logging

Uncomment in `main.tf`:
```terraform
enable_aws_for_fluentbit = true
aws_for_fluentbit = {
  namespace = "kube-system"
  enable_containerinsights = true
}
```

### Adding Karpenter (if not using Auto Mode)

```terraform
enable_karpenter = true
karpenter = {
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
}
```

---

## Cost Considerations

### EKS Add-ons
- **Metrics Server**: Free
- **CloudWatch Observability**: CloudWatch costs apply
  - Metrics: $0.30 per metric per month
  - Logs: $0.50 per GB ingested
  - Dashboards: $3 per dashboard per month

### External DNS
- **Compute**: Minimal (single pod)
- **Route53**: $0.50 per hosted zone per month
- **Queries**: $0.40 per million queries

### External Secrets
- **Compute**: Minimal (operator pod)
- **Secrets Manager**: $0.40 per secret per month
- **API Calls**: $0.05 per 10,000 calls

### CloudWatch Metrics
- **Compute**: Minimal (daemonset)
- **Metrics**: $0.30 per metric per month
- **API Calls**: Included

**Total Estimated Cost**: ~$10-20/month for basic usage

---

## Security Features

### 1. IRSA for Add-ons
- No long-lived credentials
- Least privilege IAM roles
- Automatic token rotation

### 2. Private Cluster Integration
- Add-ons work with private endpoints
- No public exposure required
- VPC endpoint support

### 3. Encrypted Secrets
- External Secrets syncs encrypted secrets
- Kubernetes secrets encrypted at rest (KMS)
- In-transit encryption (TLS)

### 4. Network Policies
- Add-ons respect network policies
- Can restrict pod-to-pod communication
- Namespace isolation

---

## Best Practices

### DO:
✅ Use IRSA for all add-ons requiring AWS access  
✅ Monitor add-on resource usage  
✅ Keep add-on versions up to date  
✅ Use External Secrets for sensitive data  
✅ Enable CloudWatch Observability for insights  
✅ Test add-ons after installation  
✅ Use namespaces for add-on isolation  
✅ Set resource limits on add-on pods

### DON'T:
❌ Hardcode AWS credentials in add-on configs  
❌ Disable Metrics Server (required for HPA)  
❌ Skip IRSA role configuration  
❌ Ignore add-on logs and metrics  
❌ Use default service accounts without IRSA  
❌ Install conflicting add-ons  
❌ Forget to configure Route53 zones for External DNS  
❌ Skip testing after add-on installation

---

## Related Documentation

- **cluster Stage**: See `docs/README-cluster.md` for EKS cluster and IRSA setup
- **nodepool Stage**: See `docs/README-nodepool.md` for node provisioning
- **common-files**: See `docs/README-common-files.md` for shared configuration
- **EKS Blueprints Addons**: https://aws-ia.github.io/terraform-aws-eks-blueprints-addons/
- **External DNS**: https://github.com/kubernetes-sigs/external-dns
- **External Secrets**: https://external-secrets.io/
- **EKS Add-ons**: https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html

---

## Summary

The addons stage installs essential Kubernetes add-ons and AWS integrations:
- **AWS Managed Add-ons**: CloudWatch Observability, Metrics Server, Network Flow Monitoring
- **External DNS**: Automatic Route53 DNS record management with IRSA
- **External Secrets**: Sync secrets from AWS Secrets Manager/Parameter Store
- **CloudWatch Metrics**: Cluster and pod metrics collection
- **Provider Configuration**: Kubernetes, Helm, and kubectl providers with exec authentication
- **IRSA Roles**: Automatically created for add-ons requiring AWS access

This configuration provides a complete observability, DNS management, and secrets management solution for the EKS cluster, enabling production-ready application deployments.
