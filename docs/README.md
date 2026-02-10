# EKS Workshop Infrastructure - Complete Overview

## Introduction

This repository contains a complete, production-ready Amazon EKS infrastructure deployment using Terraform. The infrastructure is built in stages, each building upon the previous, creating a fully functional Kubernetes cluster with observability, service mesh, and sample applications.

**Total Deployment Time**: ~40 minutes  
**Infrastructure as Code**: 100% Terraform  
**Architecture**: Modular, staged deployment  
**Purpose**: EKS workshop and production reference architecture

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│ AWS Account                                                              │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ Foundation (tf-setup)                                           │    │
│  │ - S3 Bucket (Terraform state)                                  │    │
│  │ - KMS Key (encryption)                                         │    │
│  │ - SSM Parameters (configuration registry)                      │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ Network (net)                                                   │    │
│  │ - VPC (10.141.0.0/16 + 100.65.0.0/16)                         │    │
│  │ - Public, Private, Intra Subnets (3 AZs)                      │    │
│  │ - NAT Gateway, VPC Endpoints                                   │    │
│  │ - VPC Peering (Default VPC ↔ EKS VPC)                         │    │
│  │ - Route53 Private Hosted Zone                                  │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ EKS Cluster (cluster)                                           │    │
│  │ - EKS Control Plane (Kubernetes 1.33)                          │    │
│  │ - Auto Mode Enabled                                            │    │
│  │ - IRSA (IAM Roles for Service Accounts)                        │    │
│  │ - Private API Endpoint                                         │    │
│  │ - KMS Encryption (secrets)                                     │    │
│  │ - Control Plane Logging                                        │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ Node Provisioning (nodepool)                                    │    │
│  │ - Karpenter NodeClass & NodePool                               │    │
│  │ - Flexible Instance Selection (c, m, r families)               │    │
│  │ - Spot & On-Demand Support                                     │    │
│  │ - Auto-scaling Based on Pod Requirements                       │    │
│  │ - Default Storage Class (gp3, encrypted)                       │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ Cluster Add-ons (addons)                                        │    │
│  │ - CloudWatch Observability                                     │    │
│  │ - Metrics Server                                               │    │
│  │ - Network Flow Monitoring                                      │    │
│  │ - External DNS (Route53 integration)                           │    │
│  │ - External Secrets (AWS Secrets Manager sync)                  │    │
│  │ - CloudWatch Metrics Collection                                │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ Sample Application (sampleapp)                                  │    │
│  │ - Retail Store (6 microservices)                               │    │
│  │ - Databases (MySQL, PostgreSQL, RabbitMQ, Redis)              │    │
│  │ - LoadBalancer (internet-facing NLB)                           │    │
│  │ - Production-ready security practices                          │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ Observability (observ)                                          │    │
│  │ - Amazon Managed Prometheus (AMP)                              │    │
│  │ - Amazon Managed Grafana (AMG)                                 │    │
│  │ - AWS Distro for OpenTelemetry (ADOT)                          │    │
│  │ - Pre-built Dashboards & Alerts                                │    │
│  │ - Distributed Tracing (X-Ray)                                  │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ Service Mesh (istio)                                            │    │
│  │ - Istio 1.24.3 (Control Plane + Ingress Gateway)              │    │
│  │ - Bookinfo Sample Application                                  │    │
│  │ - Traffic Management & mTLS                                    │    │
│  │ - Advanced Routing & Resilience                                │    │
│  └────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Deployment Stages

### Stage 1: tf-setup (~2 minutes)
**Purpose**: Bootstrap infrastructure and state management

**Creates**:
- S3 bucket for Terraform state (encrypted, versioned)
- KMS key for encryption
- Random ID for unique resource naming
- SSM parameters for cross-stage configuration
- Backend configuration files for all stages

**Key Outputs**:
- State bucket name
- KMS key ID and ARN
- Unique deployment ID
- Region and cluster name

**Documentation**: [README-tf-setup.md](./README-tf-setup.md)

---

### Stage 2: net (~5 minutes)
**Purpose**: Network infrastructure foundation

**Creates**:
- VPC with dual CIDR blocks (10.141.0.0/16 + 100.65.0.0/16)
- 3 subnet types across 3 AZs:
  - Public subnets (NAT Gateway, Load Balancers)
  - Private subnets (EKS nodes, 100.65.0.0/16)
  - Intra subnets (Control plane ENIs, VPC endpoints)
- Single NAT Gateway (cost optimization)
- VPC Endpoints (S3, ECR, EC2, SSM, Logs, Secrets Manager)
- VPC Peering (Default VPC ↔ EKS VPC)
- Route53 Private Hosted Zone
- Security groups and routing

**Key Features**:
- Large IP space for pods (100.65.0.0/16)
- VPC Flow Logs to CloudWatch
- Kubernetes ELB discovery tags
- Karpenter discovery tags

**Documentation**: [README-net.md](./README-net.md)

---

### Stage 3: cluster (~15 minutes)
**Purpose**: EKS cluster creation and configuration

**Creates**:
- EKS cluster (Kubernetes 1.33)
- EKS Auto Mode configuration
- OIDC provider for IRSA
- KMS key for secrets encryption
- IAM roles (cluster, nodes)
- Security groups
- Control plane logging (all log types)
- kubectl configuration

**Key Features**:
- Private API endpoint (no public access)
- Auto Mode for simplified node management
- IRSA enabled (IAM roles for pods)
- Secrets encrypted at rest (KMS)
- Authentication mode: API_AND_CONFIG_MAP
- Cluster creator admin permissions

**Documentation**: [README-cluster.md](./README-cluster.md)

---

### Stage 4: nodepool (~2 minutes)
**Purpose**: Node provisioning configuration

**Creates**:
- Karpenter NodeClass (infrastructure template)
- Karpenter NodePool (scheduling requirements)
- Default StorageClass (gp3, encrypted)
- Test deployment (inflate)

**Key Features**:
- Flexible instance selection (c, m, r families, 4-32 vCPUs)
- Spot and on-demand support
- Automatic consolidation (cost optimization)
- Node expiration (48 hours)
- Disruption budgets (controlled updates)
- Generation constraint (> 5 for modern instances)

**Documentation**: [README-nodepool.md](./README-nodepool.md)

---

### Stage 5: addons (~5 minutes)
**Purpose**: Essential cluster add-ons and integrations

**Creates**:
- AWS EKS Add-ons:
  - CloudWatch Observability (Container Insights)
  - Metrics Server (HPA, kubectl top)
  - Network Flow Monitoring Agent
- EKS Blueprints Add-ons:
  - External DNS (Route53 automation)
  - External Secrets (AWS Secrets Manager sync)
  - CloudWatch Metrics (cluster metrics)

**Key Features**:
- IRSA roles for all add-ons
- Automatic DNS record management
- Centralized secrets management
- Comprehensive metrics collection

**Documentation**: [README-addons.md](./README-addons.md)

---

### Stage 6: sampleapp (~3 minutes)
**Purpose**: E-commerce microservices demonstration

**Creates**:
- 6 microservices:
  - UI (web interface)
  - Assets (static files)
  - Catalog (product data) → MySQL
  - Carts (shopping cart) → DynamoDB
  - Orders (order processing) → PostgreSQL + RabbitMQ
  - Checkout (payment) → Redis
- 3 StatefulSets (MySQL, PostgreSQL, RabbitMQ)
- 1 Deployment (Redis)
- LoadBalancer (internet-facing NLB)

**Key Features**:
- Production-ready security (non-root, read-only filesystem)
- Health checks and readiness probes
- Resource requests and limits
- Persistent storage for databases
- IRSA service accounts

**Documentation**: [README-sampleapp.md](./README-sampleapp.md)

---

### Stage 7: observ (~10 minutes)
**Purpose**: Comprehensive observability stack

**Creates**:
- Amazon Managed Prometheus (AMP) workspace
- Amazon Managed Grafana (AMG) workspace
- AWS Distro for OpenTelemetry (ADOT) operator
- Cert Manager (TLS certificates)
- External Secrets Operator
- Pre-built dashboards (cluster, workload, application)
- Alert Manager configuration

**Key Features**:
- Fully managed Prometheus and Grafana
- Automatic dashboard provisioning
- Distributed tracing (X-Ray)
- SAML authentication (Keycloak)
- 150-day metrics retention
- PromQL query engine

**Documentation**: [README-observ.md](./README-observ.md)

---

### Stage 8: istio (~5 minutes)
**Purpose**: Service mesh for advanced microservices management

**Creates**:
- Istio 1.24.3:
  - Istio Base (CRDs)
  - Istiod (control plane)
  - Istio Ingress Gateway (NLB)
- Bookinfo sample application:
  - Product Page
  - Details
  - Reviews (v1, v2, v3)
  - Ratings

**Key Features**:
- Automatic sidecar injection
- Traffic management (routing, splitting, fault injection)
- Mutual TLS (mTLS)
- Circuit breaking and retries
- Distributed tracing
- Access logs and metrics

**Documentation**: [README-istio.md](./README-istio.md)

---

## Common Files Architecture

**Purpose**: DRY (Don't Repeat Yourself) principle implementation

**Shared Files** (symlinked to stages):
- `aws.tf` - Provider configuration
- `aws-data.tf` - AWS data sources
- `vars-main.tf` - Common variables
- `data-params-setup.tf` - Setup stage parameters
- `data-params-net.tf` - Network stage parameters
- `data-params-cluster.tf` - Cluster stage parameters
- `data-params-iam.tf` - IAM configuration parameters

**Benefits**:
- Single source of truth
- Consistent provider versions
- Reduced duplication
- Easy maintenance

**Documentation**: [README-common-files.md](./README-common-files.md)

---

## Key Technologies

### Infrastructure
- **Terraform**: Infrastructure as Code (v1.12.0+)
- **AWS EKS**: Managed Kubernetes service (v1.33)
- **Karpenter**: Kubernetes node autoscaler
- **VPC**: Dual CIDR networking

### Observability
- **Amazon Managed Prometheus**: Metrics storage
- **Amazon Managed Grafana**: Visualization
- **ADOT**: OpenTelemetry collection
- **CloudWatch**: Logs and additional metrics
- **X-Ray**: Distributed tracing

### Service Mesh
- **Istio**: Traffic management and security
- **Envoy**: Sidecar proxy
- **mTLS**: Service-to-service encryption

### Add-ons
- **External DNS**: Automatic DNS management
- **External Secrets**: Secrets synchronization
- **Cert Manager**: TLS certificate management
- **Metrics Server**: Resource metrics

---

## Security Features

### Network Security
✅ Private subnets for all workloads  
✅ Private EKS API endpoint  
✅ VPC endpoints (no internet for AWS services)  
✅ Security groups with least privilege  
✅ VPC Flow Logs enabled  
✅ Network policies supported

### Identity & Access
✅ IRSA for pod-level IAM permissions  
✅ No long-lived credentials  
✅ Service accounts for all workloads  
✅ OIDC provider for authentication  
✅ Cluster creator admin permissions  
✅ Customer-managed IAM roles

### Data Protection
✅ KMS encryption for secrets  
✅ Encrypted EBS volumes (gp3)  
✅ Encrypted S3 state bucket  
✅ TLS for all communications  
✅ mTLS with Istio  
✅ Secrets Manager integration

### Container Security
✅ Non-root containers  
✅ Read-only root filesystem  
✅ Dropped capabilities  
✅ No privilege escalation  
✅ Security contexts enforced  
✅ Image scanning (optional)

---

## Cost Breakdown

### Daily Estimates (us-east-1)

| Component | Daily Cost | Notes |
|-----------|------------|-------|
| **EKS Cluster** | $2.43 | Control plane ($73/month) |
| **EC2 Instances** | $1.00-2.00 | 1-2 nodes (Karpenter managed) |
| **NAT Gateway** | $1.07 | Single NAT + data transfer |
| **VPC Endpoints** | $1.67 | ~7 interface endpoints |
| **EBS Volumes** | $0.50 | ~150Gi total (gp3) |
| **Network Load Balancers** | $1.07 | 2 NLBs (sampleapp, istio) |
| **Amazon Managed Prometheus** | $1.67-3.33 | Metrics ingestion/storage |
| **Amazon Managed Grafana** | $0.30-1.50 | 1-5 active users |
| **CloudWatch** | $0.67-1.67 | Logs and metrics |
| **X-Ray** | $0.33-0.67 | Distributed tracing |
| **Route53** | $0.03 | Private hosted zone |
| **S3** | $0.03 | Terraform state |
| **Data Transfer** | $0.33-1.00 | Varies by usage |

**Total Estimated Cost**: **$11.10-17.43/day** (or **$333-523/month**)

### Cost Optimization Tips
- Use spot instances (up to 90% savings)
- Enable Karpenter consolidation
- Right-size resource requests
- Use VPC endpoints (reduce NAT costs)
- Set CloudWatch log retention
- Monitor and optimize metrics cardinality

---

## Resource Counts

### AWS Resources
- **VPCs**: 1 (EKS VPC)
- **Subnets**: 9 (3 public, 3 private, 3 intra)
- **NAT Gateways**: 1
- **VPC Endpoints**: 13
- **Security Groups**: 5+
- **Route Tables**: 3
- **EKS Cluster**: 1
- **KMS Keys**: 2
- **S3 Buckets**: 1
- **SSM Parameters**: 20+
- **IAM Roles**: 10+
- **Load Balancers**: 2-3

### Kubernetes Resources
- **Namespaces**: 10+
- **Deployments**: 15+
- **StatefulSets**: 3
- **Services**: 20+
- **ConfigMaps**: 10+
- **Secrets**: 5+
- **Service Accounts**: 15+
- **Pods**: 30-50 (varies)

---

## Prerequisites

### Required Tools
- **Terraform**: v1.12.0 or later
- **AWS CLI**: v2.x
- **kubectl**: v1.33 or compatible
- **jq**: For JSON parsing in scripts

### AWS Requirements
- AWS account with appropriate permissions
- AWS credentials configured (`~/.aws/credentials`)
- Sufficient service quotas (VPCs, EIPs, EKS clusters)

### Local Environment
- **OS**: macOS, Linux, or WSL2
- **Shell**: bash or zsh
- **Disk Space**: ~5GB for Terraform providers and state
- **Network**: Internet access for provider downloads

---

## Deployment Instructions

### Quick Start

```bash
# 1. Clone repository
git clone <repository-url>
cd terraform-eks-code-automode-ipv4

# 2. Configure AWS credentials
aws configure

# 3. Deploy all stages (automated)
cd .aws-staff
./build-all.sh

# 4. Access applications
# Get sampleapp URL
kubectl get svc -n sampleapp ui

# Get Grafana URL
aws grafana list-workspaces

# Get Istio ingress URL
kubectl get svc -n istio-ingress istio-ingress
```

### Manual Stage-by-Stage Deployment

```bash
# Stage 1: Foundation
cd tf-setup
terraform init
terraform plan
terraform apply

# Stage 2: Network
cd ../net
terraform init
terraform plan
terraform apply

# Stage 3: Cluster
cd ../cluster
terraform init
terraform plan
terraform apply

# Stage 4: Node Provisioning
cd ../nodepool
terraform init
terraform plan
terraform apply

# Stage 5: Add-ons
cd ../addons
terraform init
terraform plan
terraform apply

# Stage 6: Sample Application (optional)
cd ../sampleapp
terraform init
terraform plan
terraform apply

# Stage 7: Observability (optional)
cd ../observ
terraform init
terraform plan
terraform apply

# Stage 8: Service Mesh (optional)
cd ../istio
terraform init
terraform plan
terraform apply
```

---

## Verification & Testing

### Cluster Health

```bash
# Verify cluster access
kubectl get nodes
kubectl get pods -A

# Check EKS cluster status
aws eks describe-cluster --name eks-workshop

# Verify add-ons
kubectl get pods -n kube-system
kubectl get pods -n external-dns
kubectl get pods -n external-secrets

# Test metrics server
kubectl top nodes
kubectl top pods -A
```

### Application Testing

```bash
# Sample app
export SAMPLEAPP_URL=$(kubectl get svc -n sampleapp ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$SAMPLEAPP_URL

# Istio Bookinfo
export ISTIO_URL=$(kubectl get svc -n istio-ingress istio-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$ISTIO_URL/productpage
```

### Observability

```bash
# Grafana
aws grafana describe-workspace --workspace-id <workspace-id>

# Prometheus
aws amp list-workspaces

# CloudWatch Logs
aws logs tail /aws/eks/eks-workshop/cluster --follow
```

---

## Cleanup

### Complete Teardown

```bash
# Destroy in reverse order
cd istio && terraform destroy -auto-approve
cd ../observ && terraform destroy -auto-approve
cd ../sampleapp && terraform destroy -auto-approve
cd ../addons && terraform destroy -auto-approve
cd ../nodepool && terraform destroy -auto-approve
cd ../cluster && terraform destroy -auto-approve
cd ../net && terraform destroy -auto-approve
cd ../tf-setup && terraform destroy -auto-approve
```

### Automated Cleanup

```bash
cd .aws-staff
./destroy-everything.sh
```

**Warning**: This will delete all resources including:
- EKS cluster and nodes
- VPC and networking
- Load balancers
- Persistent volumes
- S3 state bucket (if force_destroy enabled)

---

## Troubleshooting

### Common Issues

#### Issue: Terraform state locked
**Solution**: 
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

#### Issue: kubectl connection refused
**Solution**:
```bash
# Update kubeconfig
aws eks update-kubeconfig --name eks-workshop

# Verify VPC peering
aws ec2 describe-vpc-peering-connections
```

#### Issue: Pods pending
**Solution**:
```bash
# Check node capacity
kubectl get nodes
kubectl describe nodes

# Scale inflate to trigger node provisioning
kubectl scale deployment inflate --replicas=3

# Check Karpenter logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter
```

#### Issue: LoadBalancer not provisioning
**Solution**:
```bash
# Check service events
kubectl describe svc <service-name> -n <namespace>

# Verify subnet tags
aws ec2 describe-subnets --filters "Name=tag:kubernetes.io/role/elb,Values=1"
```

---

## Best Practices Implemented

### Infrastructure
✅ Modular, staged deployment  
✅ Immutable infrastructure  
✅ Infrastructure as Code (100%)  
✅ State management (S3 + encryption)  
✅ Configuration registry (SSM)  
✅ DRY principle (common files)

### Networking
✅ Multi-AZ deployment  
✅ Private subnets for workloads  
✅ VPC endpoints (cost + security)  
✅ Proper CIDR allocation  
✅ Network segmentation  
✅ Flow logs enabled

### Kubernetes
✅ Private API endpoint  
✅ IRSA for pod permissions  
✅ Resource requests/limits  
✅ Health checks  
✅ Security contexts  
✅ Namespace isolation

### Observability
✅ Comprehensive metrics  
✅ Centralized logging  
✅ Distributed tracing  
✅ Pre-built dashboards  
✅ Alert configuration  
✅ Access logs enabled

### Security
✅ Encryption at rest  
✅ Encryption in transit  
✅ Least privilege IAM  
✅ No long-lived credentials  
✅ Security groups  
✅ Network policies support

---

## Production Considerations

### Before Production Use

**Review and Modify**:
1. **NAT Gateway**: Use one per AZ (not single)
2. **S3 Bucket**: Remove `force_destroy = true`
3. **Backup Strategy**: Implement EBS snapshots, database backups
4. **Disaster Recovery**: Multi-region setup, backup/restore procedures
5. **Monitoring**: Set up alerts and on-call rotation
6. **Cost Management**: Implement budgets and cost allocation tags
7. **Security**: Enable GuardDuty, Security Hub, Inspector
8. **Compliance**: Implement required compliance controls
9. **Documentation**: Update for your organization
10. **Testing**: Implement automated testing and validation

**Add**:
- CI/CD pipeline integration
- Automated testing (unit, integration, e2e)
- Backup and restore procedures
- Disaster recovery plan
- Runbooks and playbooks
- Change management process
- Security scanning (Trivy, Snyk)
- Policy enforcement (OPA, Kyverno)

---

## Additional Resources

### Documentation
- [tf-setup Stage](./README-tf-setup.md) - Foundation and state management
- [common-files](./README-common-files.md) - Shared configuration
- [net Stage](./README-net.md) - Network infrastructure
- [cluster Stage](./README-cluster.md) - EKS cluster
- [nodepool Stage](./README-nodepool.md) - Node provisioning
- [addons Stage](./README-addons.md) - Cluster add-ons
- [sampleapp Stage](./README-sampleapp.md) - Sample application
- [observ Stage](./README-observ.md) - Observability stack
- [istio Stage](./README-istio.md) - Service mesh

### External Links
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Karpenter Documentation](https://karpenter.sh/)
- [Istio Documentation](https://istio.io/)
- [AWS Observability Accelerator](https://aws-observability.github.io/terraform-aws-observability-accelerator/)

---

## Summary

This infrastructure provides a **complete, production-ready EKS environment** with:

- ✅ **Automated deployment** (~40 minutes)
- ✅ **Modular architecture** (9 stages)
- ✅ **Security best practices** (IRSA, encryption, private endpoints)
- ✅ **Cost optimization** (Karpenter, spot instances, consolidation)
- ✅ **Comprehensive observability** (AMP, AMG, ADOT, dashboards)
- ✅ **Service mesh** (Istio for advanced traffic management)
- ✅ **Sample applications** (microservices demonstrations)
- ✅ **Full documentation** (architecture, troubleshooting, best practices)

The infrastructure demonstrates AWS best practices for EKS deployments and serves as both a workshop environment and a reference architecture for production use.

**Total Resources**: 100+ AWS resources, 50+ Kubernetes resources  
**Estimated Cost**: $11.10-17.43/day ($333-523/month)  
**Deployment Time**: ~40 minutes  
**Documentation**: Complete with examples and troubleshooting

---

## License

See [LICENSE](../LICENSE) file for details.

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

## Code of Conduct

See [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md) for community guidelines.
