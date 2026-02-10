## Terraform EKS Workshop Code

This repository contains a complete, production-ready Amazon EKS infrastructure deployment using Terraform. The infrastructure is built in modular stages, creating a fully functional Kubernetes cluster with Auto Mode, observability, service mesh, and sample applications.

**Workshop**: https://tf-eks-workshop.workshop.aws/

---

## What Gets Created

A complete EKS environment with:

- **EKS Cluster** (Kubernetes 1.33) with Auto Mode and private API endpoint
- **Network Infrastructure** - VPC with dual CIDR blocks, 3 AZs, VPC endpoints
- **Node Provisioning** - Karpenter for automatic, cost-optimized scaling
- **Observability Stack** - Amazon Managed Prometheus, Grafana, ADOT, dashboards
- **Service Mesh** - Istio 1.24.3 with traffic management and mTLS
- **Sample Applications** - E-commerce microservices and Bookinfo demos
- **Security** - IRSA, KMS encryption, private endpoints, security best practices

**Total Resources**: 100+ AWS resources, 50+ Kubernetes resources  
**Deployment Time**: ~40 minutes (automated)  
**Estimated Cost**: $11.10-17.43/day ($333-523/month)

---

## Quick Start

### Prerequisites

- Terraform v1.12.0+
- AWS CLI v2.x
- kubectl v1.33+
- jq
- AWS credentials configured

### Deploy Everything

```bash
# Clone repository
git clone <repository-url>
cd terraform-eks-code-automode-ipv4

# Configure AWS credentials
aws configure

# Deploy all stages (automated)
cd .aws-staff
./build-all.sh
```

### Access Applications

```bash
# Sample e-commerce app
kubectl get svc -n sampleapp ui

# Grafana (observability)
aws grafana list-workspaces

# Istio Bookinfo
kubectl get svc -n istio-ingress istio-ingress
```

---

## Deployment Stages

The infrastructure is deployed in 9 modular stages:

1. **tf-setup** (~2 min) - S3 state bucket, KMS keys, SSM parameters
2. **net** (~5 min) - VPC, subnets, VPC endpoints, peering
3. **cluster** (~15 min) - EKS cluster with Auto Mode and IRSA
4. **nodepool** (~2 min) - Karpenter node provisioning configuration
5. **addons** (~5 min) - External DNS, External Secrets, metrics
6. **sampleapp** (~3 min) - E-commerce microservices application
7. **observ** (~10 min) - Prometheus, Grafana, ADOT, dashboards
8. **istio** (~5 min) - Service mesh with Bookinfo sample

Each stage builds upon the previous, with configuration shared via SSM Parameter Store.

---

## Key Features

### Security
- Private EKS API endpoint
- IRSA (IAM Roles for Service Accounts)
- KMS encryption for secrets and storage
- VPC endpoints (no internet for AWS services)
- Non-root containers with security contexts
- mTLS with Istio service mesh

### Cost Optimization
- Karpenter auto-scaling (right-sizing)
- Spot instance support (up to 90% savings)
- Automatic node consolidation
- Single NAT Gateway (workshop mode)
- VPC endpoints (reduced NAT costs)

### Observability
- Amazon Managed Prometheus (metrics)
- Amazon Managed Grafana (visualization)
- Pre-built dashboards (cluster, workload, application)
- CloudWatch Observability (Container Insights)
- Distributed tracing (X-Ray)
- Access logs and metrics

### High Availability
- Multi-AZ deployment (3 availability zones)
- Auto Mode for simplified node management
- Karpenter for automatic scaling
- Load balancers for applications
- Persistent storage for databases

---

## Documentation

Comprehensive documentation available in the `docs/` directory:

- **[Overview](docs/README-overview.md)** - Complete architecture and deployment guide
- **[tf-setup](docs/README-tf-setup.md)** - Foundation and state management
- **[common-files](docs/README-common-files.md)** - Shared configuration (DRY)
- **[net](docs/README-net.md)** - Network infrastructure
- **[cluster](docs/README-cluster.md)** - EKS cluster with Auto Mode
- **[nodepool](docs/README-nodepool.md)** - Karpenter node provisioning
- **[addons](docs/README-addons.md)** - Cluster add-ons and integrations
- **[sampleapp](docs/README-sampleapp.md)** - E-commerce sample application
- **[observ](docs/README-observ.md)** - Observability stack
- **[istio](docs/README-istio.md)** - Service mesh

Each document includes architecture diagrams, configuration details, testing procedures, and troubleshooting guides.

---

## Architecture Highlights

### Network Design
- **Primary CIDR**: 10.141.0.0/16 (public, intra subnets)
- **Secondary CIDR**: 100.65.0.0/16 (private subnets for nodes)
- **Subnets**: Public, Private, Intra across 3 AZs
- **Connectivity**: VPC peering for VSCode/Cloud9 access

### EKS Configuration
- **Version**: Kubernetes 1.33
- **Compute**: Auto Mode (AWS-managed nodes)
- **API Endpoint**: Private only
- **Authentication**: API_AND_CONFIG_MAP mode
- **Encryption**: KMS for secrets
- **Logging**: All control plane logs enabled

### Node Management
- **Autoscaler**: Karpenter
- **Instance Types**: c, m, r families (4-32 vCPUs)
- **Capacity**: On-demand and spot instances
- **Policies**: Consolidation, expiration, disruption budgets
- **Storage**: gp3 encrypted volumes

---

## Cleanup

```bash
# Automated cleanup (destroys all stages in reverse order)
cd .aws-staff
./destroy-everything.sh

# Or manual stage-by-stage
cd istio && terraform destroy -auto-approve
cd ../observ && terraform destroy -auto-approve
cd ../sampleapp && terraform destroy -auto-approve
cd ../addons && terraform destroy -auto-approve
cd ../nodepool && terraform destroy -auto-approve
cd ../cluster && terraform destroy -auto-approve
cd ../net && terraform destroy -auto-approve
cd ../tf-setup && terraform destroy -auto-approve
```

---

## Design Philosophy

### Modular Architecture
Each stage is independent and can be deployed/destroyed separately. Configuration is shared via SSM Parameter Store, creating clear contracts between stages.

### DRY Principle
Common configuration files are symlinked into stages, ensuring consistency and reducing duplication. Update once, apply everywhere.

### Infrastructure as Code
100% Terraform - no manual steps, no eksctl, no console clicks. Everything is version-controlled and reproducible.

### Production-Ready
Implements AWS best practices for security, cost optimization, high availability, and observability. Can be adapted for production use with documented modifications.

---

## Code Generation

Much of the Terraform code was originally created using:

**aws2tf**: https://github.com/aws-samples/aws2tf

This tool reverse-engineers existing AWS infrastructure into Terraform code, making it easy to adopt IaC for existing environments.

---

## Contributing

Contributions and comments are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

See [LICENSE](LICENSE) file for details.

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community guidelines.



