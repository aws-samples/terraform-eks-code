# cluster Stage Documentation

## Overview

The `cluster` stage creates the Amazon EKS (Elastic Kubernetes Service) cluster with Auto Mode enabled, configures IRSA (IAM Roles for Service Accounts), sets up cluster authentication, and stores cluster configuration in SSM Parameter Store for downstream stages.

**Execution Time**: ~15-20 minutes (part of the ~40 minute total build)  
**Dependencies**: tf-setup (SSM parameters), net (VPC and subnets)  
**Outputs**: EKS cluster, OIDC provider, IAM roles, cluster endpoint, security groups  
**Next Stage**: nodepool (creates managed node groups or uses Auto Mode)

---

## Architecture Overview

### EKS Cluster Design

```
┌─────────────────────────────────────────────────────────────────┐
│ EKS Control Plane (AWS Managed)                                 │
│ - Kubernetes API Server                                         │
│ - etcd                                                           │
│ - Controller Manager                                            │
│ - Scheduler                                                      │
│                                                                  │
│ Control Plane ENIs in Intra Subnets                            │
│ (10.141.52.0/24, 10.141.53.0/24, 10.141.54.0/24)              │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 │ Private API Endpoint
                 │ (No Public Access)
                 │
┌────────────────▼────────────────────────────────────────────────┐
│ EKS VPC (10.141.0.0/16 + 100.65.0.0/16)                        │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Private Subnets (100.65.0.0/18 per AZ)                  │  │
│  │ - Worker Nodes (Auto Mode or Managed Node Groups)       │  │
│  │ - Application Pods                                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Security Groups:                                               │
│  - Cluster Security Group (created by EKS)                     │
│  - Node Security Group (created by EKS)                        │
│  - Additional rules for VSCode/Cloud9 access                   │
└──────────────────────────────────────────────────────────────────┘
                 │
                 │ VPC Peering
                 │
┌────────────────▼────────────────────────────────────────────────┐
│ Default VPC                                                      │
│ - VSCode/Cloud9 Instance (kubectl access)                      │
└──────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ IAM OIDC Provider                                                │
│ - Enables IRSA (IAM Roles for Service Accounts)                │
│ - Allows pods to assume IAM roles                               │
└──────────────────────────────────────────────────────────────────┘
```

---

## Key Features

### 1. EKS Auto Mode
- **Enabled**: `cluster_compute_config.enabled = true`
- **Node Pools**: Empty array (configured in nodepool stage)
- **Benefits**:
  - Simplified node management
  - Automatic scaling
  - Reduced operational overhead
  - AWS manages node lifecycle

### 2. Private Cluster
- **Public Access**: Disabled (`cluster_endpoint_public_access = false`)
- **Private Access**: Enabled (`cluster_endpoint_private_access = true`)
- **Access Method**: Via VPC peering from VSCode/Cloud9
- **Security**: API endpoint not exposed to internet

### 3. IRSA (IAM Roles for Service Accounts)
- **Enabled**: `enable_irsa = true`
- **OIDC Provider**: Automatically created
- **Purpose**: Allows Kubernetes pods to assume IAM roles
- **Use Cases**: S3 access, DynamoDB, Secrets Manager, etc.

### 4. Cluster Encryption
- **Secrets Encryption**: Enabled with external KMS key
- **Key Management**: Separate KMS module
- **Resources Encrypted**: Kubernetes secrets at rest

### 5. Control Plane Logging
- **Enabled Logs**: api, audit, authenticator, controllerManager, scheduler
- **Destination**: CloudWatch Logs
- **Retention**: Managed by CloudWatch
- **Use Cases**: Troubleshooting, compliance, security analysis

### 6. Authentication Mode
- **Mode**: `API_AND_CONFIG_MAP`
- **Supports**: Both EKS API and ConfigMap-based auth
- **Flexibility**: Allows gradual migration to EKS API
- **Cluster Creator**: Automatically granted admin permissions

---

## File-by-File Breakdown

### Core Infrastructure

#### main.tf
**Purpose**: Creates the EKS cluster using the AWS EKS Terraform module

**Key Components**:

##### Provider Configuration
```terraform
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}
```
- **Virginia Provider**: Required for ECR Public authentication
- **ECR Public**: Hosts public container images

##### Local Variables
```terraform
locals {
  name            = nonsensitive(data.aws_ssm_parameter.tf-eks-cluster-name.value)
  cluster_version = data.aws_ssm_parameter.tf-eks-version.value
  region          = data.aws_ssm_parameter.tf-eks-region.value
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  tags            = { created-by = "eks-workshop-v2", env = ... }
}
```
- Reads configuration from SSM parameters
- Uses first 3 AZs for high availability
- Standard tagging for resource management

##### EKS Module Configuration
```terraform
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.1"
  
  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = false
  cluster_endpoint_private_access = true
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  enable_irsa = true
  enable_cluster_creator_admin_permissions = true
  authentication_mode = "API_AND_CONFIG_MAP"
  
  cluster_compute_config = {
    enabled    = true
    node_pools = []
  }
}
```

**Network Configuration**:
- **VPC**: From net stage SSM parameter
- **Worker Subnets**: Private subnets (100.65.0.0/16)
- **Control Plane Subnets**: Intra subnets (10.141.52-54.0/24)

**Security Configuration**:
- **Additional Rules**: Allow 443 from default VPC CIDR
- **Purpose**: Enable kubectl access from VSCode/Cloud9

##### KMS Module
```terraform
module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"
  
  aliases               = ["eks/{cluster-name}"]
  description           = "{cluster-name} cluster encryption key"
  enable_default_policy = true
  key_owners            = [data.aws_caller_identity.current.arn]
}
```
- **Purpose**: Encrypt Kubernetes secrets at rest
- **Alias**: `eks/eks-workshop`
- **Owners**: Current AWS account/user
- **Policy**: Default KMS key policy enabled

##### Disabled EKS Module
```terraform
module "disabled_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.1"
  create = false
}
```
- **Purpose**: Example/template for conditional cluster creation
- **Not Used**: `create = false`

---

### IAM and Access Control

#### podi-association.tf
**Purpose**: Configures EKS Auto Mode node access policies

**Resources**:

##### Access Entry
```terraform
resource "aws_eks_access_entry" "automode_node" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.eks.node_iam_role_arn
  type          = "EC2"
}
```
- **Type**: EC2 (for Auto Mode nodes)
- **Principal**: Node IAM role
- **Purpose**: Grants nodes access to cluster

##### Access Policy Association
```terraform
resource "aws_eks_access_policy_association" "automode_node" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy"
  principal_arn = module.eks.node_iam_role_arn
  access_scope {
    type = "cluster"
  }
}
```
- **Policy**: `AmazonEKSAutoNodePolicy`
- **Scope**: Cluster-wide
- **Purpose**: Allows Auto Mode to manage nodes

#### role-add.tf
**Purpose**: Attaches additional IAM policies to node role

**Policy Attached**:
```terraform
resource "aws_iam_role_policy_attachment" "additional_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = module.eks.node_iam_role_name
}
```
- **Policy**: `CloudWatchAgentServerPolicy`
- **Purpose**: Allows nodes to send metrics/logs to CloudWatch
- **Use Case**: Observability, monitoring

**Commented Policies** (not needed for Auto Mode):
- `AmazonSSMManagedInstanceCore` - SSM access (Auto Mode handles this)
- `AmazonEKSWorkerNodePolicy` - Already included in Auto Mode
- `AmazonEC2ContainerRegistryReadOnly` - Already included
- `AmazonEBSCSIDriverPolicy` - Managed separately

---

### Security Groups

#### sg-rule-eks.tf
**Purpose**: Adds security group rules for cluster access

**Rules**:

##### Ingress from Default VPC
```terraform
resource "aws_security_group_rule" "eks-all" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.vpc-default.cidr_block]
  security_group_id = module.eks.cluster_primary_security_group_id
}
```
- **Port**: 443 (HTTPS/Kubernetes API)
- **Source**: Default VPC CIDR
- **Purpose**: Allow kubectl from VSCode/Cloud9

##### Egress to Default VPC
```terraform
resource "aws_security_group_rule" "eks-all-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = module.eks.cluster_primary_security_group_id
  cidr_blocks       = [data.aws_vpc.vpc-default.cidr_block]
}
```
- **Ports**: All
- **Destination**: Default VPC CIDR
- **Purpose**: Allow cluster to communicate with default VPC

---

### Data Sources

#### data-aws.tf
**Purpose**: Retrieves AWS account and region information

```terraform
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
```
- Used for KMS key ownership
- Used for resource tagging

#### data-defvpc.tf
**Purpose**: Retrieves default VPC information

```terraform
data "aws_vpc" "vpc-default" {
  default = true
}
```
- Used for security group rules
- Used for VPC peering validation

#### data-eks.tf
**Purpose**: Retrieves EKS cluster and OIDC provider information

```terraform
data "aws_iam_openid_connect_provider" "example" {
  depends_on = [module.eks]
  url = format("https://%s", module.eks.oidc_provider)
}

data "aws_eks_cluster" "example" {
  depends_on = [module.eks]
  name = module.eks.cluster_name
}
```
- **OIDC Provider**: Used for IRSA configuration
- **Cluster Data**: Used for validation and outputs
- **Depends On**: Ensures cluster is created first

---

### SSM Parameters

#### ssm-params-cluster.tf
**Purpose**: Stores cluster configuration for downstream stages

**Parameters Created**:

| Parameter | Value | Used By |
|-----------|-------|---------|
| `/workshop/tf-eks/oidc_provider_arn` | OIDC provider ARN | IRSA role creation |
| `/workshop/tf-eks/eks-cluster-name` | Cluster name | kubectl configuration |
| `/workshop/tf-eks/cluster-sg` | Primary security group ID | Security rules |
| `/workshop/tf-eks/ca` | Certificate authority data | kubectl/Helm config |
| `/workshop/tf-eks/endpoint` | API endpoint URL | kubectl/Helm config |
| `/workshop/tf-eks/eks-node-role-name` | Node IAM role name | Additional policies |

**Usage Example**:
```terraform
# In addons stage
data "aws_ssm_parameter" "oidc_provider_arn" {
  name = "/workshop/tf-eks/oidc_provider_arn"
}

resource "aws_iam_role" "irsa_role" {
  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_ssm_parameter.oidc_provider_arn.value
      }
      Action = "sts:AssumeRoleWithWebIdentity"
    }]
  })
}
```

---

### Cluster Authentication

#### null_auth.tf
**Purpose**: Configures kubectl access after cluster creation

```terraform
resource "null_resource" "gen_cluster_auth" {
  triggers = {
    always_run = timestamp()
  }
  depends_on = [module.eks]
  provisioner "local-exec" {
    command = <<EOT
      CLUSTER_NAME=$(echo ${nonsensitive(data.aws_ssm_parameter.tf-eks-cluster-name.value)})
      aws eks update-kubeconfig --name $CLUSTER_NAME
      kubectl version
      sleep 10
    EOT
  }
}
```

**Actions**:
1. Updates `~/.kube/config` with cluster credentials
2. Verifies kubectl connectivity
3. Waits 10 seconds for cluster stabilization

**Why Needed**:
- Terraform needs kubectl access for subsequent operations
- Validates cluster is accessible
- Sets up authentication for local development

#### auth.sh
**Purpose**: Manual script for configuring kubectl access

**Actions**:
1. Removes existing kubeconfig
2. Updates kubeconfig with cluster credentials
3. Verifies kubectl connectivity
4. Configures CNI custom networking (optional)

**Usage**:
```bash
./auth.sh eks-workshop
```

**CNI Configuration** (commented out):
```bash
kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
```
- Enables custom networking for VPC CNI
- Allows pods to use different subnets than nodes
- Useful for IP address management

---

### Utility Scripts

#### test.sh
**Purpose**: Tests cluster API endpoint connectivity

```bash
./test.sh eks-workshop
```

**Actions**:
1. Describes cluster using AWS CLI
2. Extracts API endpoint hostname
3. Tests connectivity with nmap on port 443

**Use Case**: Troubleshooting private cluster access

#### private-cluster.sh
**Purpose**: Converts cluster to private endpoint only

```bash
./private-cluster.sh
```

**Actions**:
1. Modifies `main.tf` to disable public access
2. Applies changes automatically

**Warning**: Requires VPC peering or VPN for access

#### public-cluster.sh
**Purpose**: Converts cluster to public endpoint

```bash
./public-cluster.sh
```

**Actions**:
1. Modifies `main.tf` to enable public access
2. Applies changes automatically

**Use Case**: Temporary public access for troubleshooting

---

### Outputs

#### outputs.tf
**Purpose**: Exports cluster information for use by other stages and tools

**Output Categories**:

##### Cluster Information
- `cluster_arn`: Full ARN of the cluster
- `cluster_endpoint`: API server URL
- `cluster_id`: Cluster ID (for Outposts)
- `cluster_name`: Cluster name
- `cluster_status`: Current status (CREATING, ACTIVE, etc.)
- `cluster_platform_version`: EKS platform version

##### OIDC/IRSA
- `oidc_provider`: OIDC issuer URL (without https://)
- `oidc_provider_arn`: Full ARN for IAM trust policies
- `cluster_tls_certificate_sha1_fingerprint`: Certificate fingerprint

##### Security Groups
- `cluster_security_group_id`: Cluster security group
- `cluster_primary_security_group_id`: Primary SG (for rules)
- `node_security_group_id`: Node security group

##### IAM Roles
- `cluster_iam_role_arn`: Cluster service role
- `node_iam_role_arn`: Node IAM role (Auto Mode)
- `node_iam_role_name`: Node role name

##### Add-ons and Logging
- `cluster_addons`: Enabled EKS add-ons
- `cloudwatch_log_group_name`: Log group for control plane logs

---

## Symlinked Files

These files are symlinked from `common-files/`:

- **backend-cluster.tf**: S3 backend configuration (generated by tf-setup)
- **data-params-setup.tf**: Setup stage SSM parameters (cluster name, version, etc.)
- **data-params-net.tf**: Network stage SSM parameters (VPC, subnets, etc.)
- **vars-main.tf**: Common variables (region, cluster-name, etc.)

---

## Resource Dependencies

```
tf-setup (SSM params)
    ↓
net (VPC, subnets)
    ↓
cluster/main.tf
    ├─→ module.kms (encryption key)
    ├─→ module.eks (EKS cluster)
    │       ↓
    │   data-eks.tf (OIDC provider)
    │   podi-association.tf (Auto Mode access)
    │   role-add.tf (additional policies)
    │   sg-rule-eks.tf (security rules)
    │   null_auth.tf (kubectl config)
    │       ↓
    │   ssm-params-cluster.tf (store outputs)
    │       ↓
    └─→ outputs.tf
            ↓
        nodepool/addons stages
```

---

## EKS Auto Mode Details

### What is Auto Mode?

EKS Auto Mode is a fully managed compute option where AWS handles:
- Node provisioning and lifecycle
- Scaling based on pod requirements
- OS patching and updates
- Node health monitoring
- Capacity optimization

### Configuration

```terraform
cluster_compute_config = {
  enabled    = true
  node_pools = []  # Configured in nodepool stage
}
```

### Benefits

1. **Simplified Operations**: No manual node group management
2. **Cost Optimization**: AWS optimizes instance selection
3. **Automatic Scaling**: Scales based on pod requirements
4. **Reduced Overhead**: No need to manage node lifecycle

### Required Policies

- `AmazonEKSAutoNodePolicy`: Cluster-level access for Auto Mode
- `CloudWatchAgentServerPolicy`: Metrics and logging

### Access Configuration

```terraform
resource "aws_eks_access_entry" "automode_node" {
  type = "EC2"  # EC2 type for Auto Mode nodes
}

resource "aws_eks_access_policy_association" "automode_node" {
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy"
  access_scope {
    type = "cluster"  # Cluster-wide access
  }
}
```

---

## IRSA (IAM Roles for Service Accounts)

### Architecture

```
Kubernetes Pod
    ↓
Service Account (with annotation)
    ↓
OIDC Provider (validates token)
    ↓
IAM Role (trust policy with OIDC)
    ↓
AWS Service (S3, DynamoDB, etc.)
```

### Configuration

1. **Enable IRSA**: `enable_irsa = true`
2. **OIDC Provider**: Automatically created by EKS module
3. **Store ARN**: Saved to SSM for downstream stages

### Usage Example

```yaml
# Kubernetes ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/my-app-role
```

```terraform
# IAM Role with OIDC trust
resource "aws_iam_role" "my_app" {
  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_ssm_parameter.oidc_provider_arn.value
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${module.eks.oidc_provider}:sub": "system:serviceaccount:default:my-app"
        }
      }
    }]
  })
}
```

---

## Security Features

### 1. Private Cluster
- **Public Access**: Disabled
- **Access Method**: VPC peering from VSCode/Cloud9
- **Benefit**: API endpoint not exposed to internet

### 2. Secrets Encryption
- **Method**: KMS encryption at rest
- **Key**: Separate KMS key with rotation capability
- **Resources**: Kubernetes secrets

### 3. Control Plane Logging
- **Logs**: API, audit, authenticator, controller, scheduler
- **Destination**: CloudWatch Logs
- **Use Cases**: Security analysis, compliance, troubleshooting

### 4. Security Groups
- **Cluster SG**: Managed by EKS
- **Node SG**: Managed by EKS
- **Additional Rules**: Minimal (only VSCode/Cloud9 access)

### 5. IAM Least Privilege
- **Cluster Role**: Only necessary EKS permissions
- **Node Role**: Only necessary EC2/ECR permissions
- **IRSA**: Pod-level IAM permissions

---

## Cost Optimization

### 1. Auto Mode
- **Benefit**: AWS optimizes instance selection
- **Savings**: Right-sizing, spot instances (if configured)

### 2. Single NAT Gateway
- **Inherited**: From net stage
- **Savings**: ~$90/month vs. 3 NAT Gateways

### 3. VPC Endpoints
- **Inherited**: From net stage
- **Savings**: Reduced NAT Gateway data transfer

### 4. Control Plane Logging
- **Cost**: ~$0.50/GB ingested + storage
- **Optimization**: Can disable unused log types

---

## Testing and Verification

### After Deployment

```bash
# Verify cluster exists
aws eks describe-cluster --name eks-workshop

# Check cluster status
aws eks describe-cluster --name eks-workshop --query 'cluster.status'

# Update kubeconfig
aws eks update-kubeconfig --name eks-workshop

# Test kubectl access
kubectl version
kubectl get nodes
kubectl get pods -A

# Verify OIDC provider
aws iam list-open-id-connect-providers

# Check SSM parameters
aws ssm get-parameters-by-path --path /workshop/tf-eks/ --recursive

# Verify control plane logs
aws logs describe-log-groups --log-group-name-prefix /aws/eks/eks-workshop

# Test API endpoint connectivity (from VSCode/Cloud9)
kubectl cluster-info
```

---

## Common Issues

### Issue: Cluster creation timeout
**Cause**: AWS service delay or network issues  
**Solution**: Wait and retry, check VPC/subnet configuration

### Issue: kubectl connection refused
**Cause**: Private cluster, no VPC peering  
**Solution**: Verify VPC peering, check security group rules

### Issue: OIDC provider not found
**Cause**: IRSA not enabled or cluster not fully created  
**Solution**: Verify `enable_irsa = true`, wait for cluster to be ACTIVE

### Issue: Nodes not joining cluster
**Cause**: Auto Mode not configured, IAM permissions  
**Solution**: Check access entry and policy association

### Issue: Control plane logs not appearing
**Cause**: Log types not enabled or CloudWatch permissions  
**Solution**: Verify `cluster_enabled_log_types`, check IAM role

### Issue: Secrets not encrypted
**Cause**: KMS key not configured  
**Solution**: Verify KMS module and encryption config

---

## Extending the Cluster

### Adding More Log Types

```terraform
cluster_enabled_log_types = [
  "api",
  "audit",
  "authenticator",
  "controllerManager",
  "scheduler"
]
```

### Enabling Public Access (Temporarily)

```terraform
cluster_endpoint_public_access = true
cluster_endpoint_public_access_cidrs = ["YOUR_IP/32"]
```

### Adding Cluster Add-ons

```terraform
cluster_addons = {
  coredns = {
    most_recent = true
  }
  kube-proxy = {
    most_recent = true
  }
  vpc-cni = {
    most_recent = true
  }
}
```

### Custom Node Pools (Auto Mode)

```terraform
cluster_compute_config = {
  enabled    = true
  node_pools = ["general-purpose", "system"]
}
```

---

## Best Practices

### DO:
✅ Use private clusters for production  
✅ Enable IRSA for pod-level IAM permissions  
✅ Encrypt secrets with KMS  
✅ Enable control plane logging  
✅ Use Auto Mode for simplified operations  
✅ Store cluster config in SSM parameters  
✅ Use VPC endpoints to reduce costs

### DON'T:
❌ Expose API endpoint to 0.0.0.0/0  
❌ Use overly permissive IAM roles  
❌ Disable control plane logging  
❌ Hardcode cluster configuration  
❌ Skip OIDC provider configuration  
❌ Use public clusters without IP restrictions  
❌ Forget to configure kubectl access

---

## Related Documentation

- **tf-setup Stage**: See `docs/README-tf-setup.md` for SSM parameter creation
- **net Stage**: See `docs/README-net.md` for network infrastructure
- **common-files**: See `docs/README-common-files.md` for shared configuration
- **nodepool Stage**: Next stage that configures node groups
- **AWS EKS Module**: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws
- **EKS Auto Mode**: https://docs.aws.amazon.com/eks/latest/userguide/auto-mode.html
- **IRSA**: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html

---

## Summary

The cluster stage creates a production-ready EKS cluster with:
- Auto Mode for simplified node management
- Private API endpoint for security
- IRSA for pod-level IAM permissions
- KMS encryption for secrets
- Comprehensive control plane logging
- VPC integration with proper subnet placement
- Security group rules for VSCode/Cloud9 access
- SSM parameters for cross-stage communication

This cluster foundation supports the nodepool and addons stages while maintaining security, scalability, and operational simplicity through Auto Mode.
