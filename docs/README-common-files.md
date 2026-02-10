# common-files Directory Documentation

## Overview

The `common-files` directory contains shared Terraform configuration files that are reused across multiple infrastructure stages. These files are symlinked into stage directories to maintain consistency and follow the DRY (Don't Repeat Yourself) principle.

**Purpose**: Centralized configuration management  
**Usage Pattern**: Symlinked into stage directories (net, cluster, nodepool, addons, observ)  
**Key Benefit**: Single source of truth for provider configuration and SSM parameter references

---

## Architecture Pattern

### Symlink Strategy

Instead of duplicating configuration files across stages, this project uses symbolic links:

```
common-files/
├── aws.tf                    # Source file
├── vars-main.tf             # Source file
└── data-params-setup.tf     # Source file

net/
├── aws.tf -> ../common-files/aws.tf                    # Symlink
├── vars-main.tf -> ../common-files/vars-main.tf       # Symlink
└── data-params-setup.tf -> ../common-files/data-params-setup.tf  # Symlink

cluster/
├── aws.tf -> ../common-files/aws.tf                    # Symlink
├── vars-main.tf -> ../common-files/vars-main.tf       # Symlink
└── data-params-setup.tf -> ../common-files/data-params-setup.tf  # Symlink
```

**Benefits**:
- Update once, apply everywhere
- Consistent provider versions across all stages
- Reduced maintenance overhead
- Prevents configuration drift

---

## File Inventory

### 1. Provider Configuration Files

#### aws.tf
**Purpose**: Terraform and AWS provider configuration  
**Symlinked to**: All stages (net, cluster, nodepool, addons, observ)

**Contents**:
- Terraform version constraint (> 1.12.0)
- Provider version locks (AWS 5.100.0, Kubernetes 2.24.0, Helm 2.17.0, etc.)
- AWS provider configuration with credentials
- Additional provider declarations (null, external)

**Key Features**:
- Ensures all stages use identical provider versions
- Prevents version conflicts between stages
- Uses local AWS credentials file for authentication

#### aws-data.tf
**Purpose**: Common AWS data sources  
**Symlinked to**: Stages that need AWS account context

**Data Sources**:
- `aws_region.current` - Current AWS region
- `aws_caller_identity.current` - AWS account ID and caller info
- `aws_availability_zones.az` - Available AZs in the region

**Usage**: Provides environment context for resource creation

---

### 2. Variable Definition Files

#### vars-main.tf
**Purpose**: Core input variables used across all stages  
**Symlinked to**: All stages

**Variables Defined**:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | string | `eu-west-1` | AWS deployment region |
| `profile` | string | `default` | AWS credentials profile |
| `cluster-name` | string | `eks-workshop` | EKS cluster name |
| `eks_version` | string | `1.33` | Kubernetes version |
| `no-output` | string | `secret` | Unused sensitive variable |

**Override Methods**:
- Environment variables: `TF_VAR_region=us-east-1`
- `.tfvars` files
- Command line: `-var="region=us-west-2"`

#### var-karpenter-version.tf
**Purpose**: Karpenter autoscaler version configuration  
**Symlinked to**: Stages that deploy or configure Karpenter

**Variable**:
```terraform
variable "karpenter_version" {
  description = "Karpenter Version"
  default     = "0.23.0"
  type        = string
}
```

**Usage**: Ensures consistent Karpenter version across nodepool and addons stages

---

### 3. SSM Parameter Data Sources

These files retrieve configuration values stored in AWS Systems Manager Parameter Store by the `tf-setup` stage.

#### data-params-setup.tf
**Purpose**: Retrieve foundational setup parameters  
**Symlinked to**: All stages

**Parameters Retrieved**:

| Parameter Path | Variable Name | Description |
|---------------|---------------|-------------|
| `/workshop/tf-eks/id` | `tf-eks-id` | Unique deployment identifier |
| `/workshop/tf-eks/keyid` | `tf-eks-keyid` | KMS key ID for encryption |
| `/workshop/tf-eks/keyarn` | `tf-eks-keyarn` | KMS key ARN |
| `/workshop/tf-eks/region` | `tf-eks-region` | Deployment region |
| `/workshop/tf-eks/cluster-name` | `tf-eks-cluster-name` | EKS cluster name |
| `/workshop/tf-eks/eks-version` | `tf-eks-version` | Kubernetes version |

**Usage Example**:
```terraform
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket-${data.aws_ssm_parameter.tf-eks-id.value}"
}
```

#### data-params-net.tf
**Purpose**: Retrieve network infrastructure parameters  
**Symlinked to**: Stages that need network information (cluster, nodepool, addons)

**Parameters Retrieved**:

| Parameter Path | Variable Name | Description |
|---------------|---------------|-------------|
| `/workshop/tf-eks/eks-vpc` | `eks-vpc` | EKS VPC ID |
| `/workshop/tf-eks/eks-cidr` | `eks-cidr` | EKS VPC CIDR block |
| `/workshop/tf-eks/cicd-cidr` | `cicd-cidr` | CI/CD VPC CIDR |
| `/workshop/tf-eks/cicd-vpc` | `cicd-vpc` | CI/CD VPC ID |
| `/workshop/tf-eks/private_subnets` | `private_subnets` | Private subnet IDs (comma-separated) |
| `/workshop/tf-eks/intra_subnets` | `intra_subnets` | Intra subnet IDs |
| `/workshop/tf-eks/private_rtb` | `private_rtb` | Private route table IDs |
| `/workshop/tf-eks/intra_rtb` | `intra_rtb` | Intra route table IDs |
| `/workshop/tf-eks/public_rtb` | `public_rtb` | Public route table IDs |
| `/workshop/tf-eks/phz-id` | `phz-id` | Private hosted zone ID |

**Commented Out** (not currently used):
- `database_subnets`
- `database_subnet_group_name`

**Usage Example**:
```terraform
resource "aws_eks_cluster" "main" {
  vpc_config {
    subnet_ids = split(",", data.aws_ssm_parameter.private_subnets.value)
  }
}
```

#### data-params-cluster.tf
**Purpose**: Retrieve EKS cluster configuration parameters  
**Symlinked to**: Stages that interact with the EKS cluster (nodepool, addons, observ)

**Parameters Retrieved**:

| Parameter Path | Variable Name | Description |
|---------------|---------------|-------------|
| `/workshop/tf-eks/oidc_provider_arn` | `oidc_provider_arn` | OIDC provider ARN for IRSA |
| `/workshop/tf-eks/cluster-name` | `cluster-name` | EKS cluster name |
| `/workshop/tf-eks/cluster-sg` | `cluster-sg` | Cluster security group ID |
| `/workshop/tf-eks/ca` | `ca` | Cluster certificate authority data |
| `/workshop/tf-eks/endpoint` | `endpoint` | Cluster API endpoint |
| `/workshop/tf-eks/eks-node-role-name` | `eks-node-role-name` | Node IAM role name |

**Usage Example**:
```terraform
# Configure Kubernetes provider
provider "kubernetes" {
  host                   = data.aws_ssm_parameter.endpoint.value
  cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
}

# Create IRSA role
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

#### data-params-iam.tf
**Purpose**: Retrieve IAM role parameters  
**Symlinked to**: Stages that need IAM role references

**Parameters Retrieved**:

| Parameter Path | Variable Name | Description |
|---------------|---------------|-------------|
| `/workshop/tf-eks/cluster_service_role_arn` | `cluster_service_role_arn` | EKS cluster service role ARN |
| `/workshop/tf-eks/nodegroup_role_arn` | `nodegroup_role_arn` | Node group IAM role ARN |
| `/workshop/tf-eks/key_name` | `key_name` | EC2 key pair name |

**Usage Example**:
```terraform
resource "aws_eks_node_group" "example" {
  node_role_arn = data.aws_ssm_parameter.nodegroup_role_arn.value
}
```

---

## Stage-Specific Symlink Patterns

### tf-setup Stage
**Symlinks**: None  
**Reason**: Bootstrap stage that creates the SSM parameters; cannot reference them

### net Stage
**Symlinks**:
- `aws.tf` (but uses generated backend)
- `aws-data.tf`
- `vars-main.tf`
- `data-params-setup.tf`

**Reason**: Needs setup parameters but doesn't reference cluster/IAM (they don't exist yet)

### cluster Stage
**Symlinks**:
- `aws.tf` (with generated backend)
- `vars-main.tf`
- `data-params-setup.tf`
- `data-params-net.tf`

**Reason**: Needs network parameters to deploy cluster into VPC

### nodepool Stage
**Symlinks**:
- `aws.tf` (with generated backend)
- `vars-main.tf`
- `data-params-setup.tf`
- `data-params-net.tf`
- `data-params-cluster.tf`
- `var-karpenter-version.tf`

**Reason**: Needs cluster and network info to create node groups

### addons Stage
**Symlinks**:
- `aws.tf` (with generated backend)
- `vars-main.tf`
- `data-params-setup.tf`
- `data-params-net.tf`
- `data-params-cluster.tf`
- `var-karpenter-version.tf`

**Reason**: Needs full context to deploy add-ons into cluster

### observ Stage
**Symlinks**:
- `aws.tf` (with generated backend)
- `vars-main.tf`
- `data-params-setup.tf`
- `data-params-cluster.tf`

**Reason**: Needs cluster info to deploy observability tools

---

## Data Flow Architecture

```
┌─────────────┐
│  tf-setup   │
│   Stage     │
└──────┬──────┘
       │ Creates SSM Parameters
       ▼
┌─────────────────────────────┐
│  AWS Systems Manager        │
│  Parameter Store            │
│  /workshop/tf-eks/*         │
└──────┬──────────────────────┘
       │ Read by
       ▼
┌─────────────────────────────┐
│  common-files/              │
│  data-params-*.tf           │
│  (Data Sources)             │
└──────┬──────────────────────┘
       │ Symlinked to
       ▼
┌─────────────────────────────┐
│  Stage Directories          │
│  net, cluster, nodepool,    │
│  addons, observ             │
└─────────────────────────────┘
```

**Flow**:
1. `tf-setup` creates SSM parameters
2. Common files define data sources to read parameters
3. Stages symlink common files
4. Stages access parameter values via data sources

---

## Benefits of This Architecture

### 1. Consistency
- All stages use identical provider versions
- No version conflicts or compatibility issues
- Uniform variable definitions

### 2. Maintainability
- Update provider version once, applies everywhere
- Add new SSM parameter data source in one place
- Easy to track what configuration is shared

### 3. Dependency Management
- Clear separation of concerns (setup → net → cluster → nodepool → addons)
- SSM parameters act as contracts between stages
- Stages can be developed/tested independently

### 4. Reduced Duplication
- ~200 lines of code shared instead of duplicated 5+ times
- Fewer files to maintain
- Lower risk of configuration drift

### 5. Flexibility
- Stages can override variables if needed
- Can add stage-specific data sources alongside common ones
- Easy to add new stages following the same pattern

---

## Common Usage Patterns

### Accessing Setup Parameters
```terraform
# In any stage with data-params-setup.tf symlinked
resource "aws_s3_bucket" "example" {
  bucket = "my-app-${data.aws_ssm_parameter.tf-eks-id.value}"
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = data.aws_ssm_parameter.tf-eks-keyid.value
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
```

### Accessing Network Parameters
```terraform
# In cluster/nodepool/addons stages
resource "aws_security_group" "example" {
  vpc_id = data.aws_ssm_parameter.eks-vpc.value
  
  ingress {
    cidr_blocks = [data.aws_ssm_parameter.eks-cidr.value]
  }
}
```

### Accessing Cluster Parameters
```terraform
# In nodepool/addons/observ stages
provider "kubernetes" {
  host                   = data.aws_ssm_parameter.endpoint.value
  cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
}

provider "helm" {
  kubernetes {
    host                   = data.aws_ssm_parameter.endpoint.value
    cluster_ca_certificate = base64decode(data.aws_ssm_parameter.ca.value)
  }
}
```

---

## Creating Symlinks

### Manual Creation
```bash
cd net/
ln -s ../common-files/aws.tf aws.tf
ln -s ../common-files/vars-main.tf vars-main.tf
ln -s ../common-files/data-params-setup.tf data-params-setup.tf
```

### Verification
```bash
# Check if symlink is correct
ls -la net/aws.tf
# Output: lrwxr-xr-x ... net/aws.tf -> ../common-files/aws.tf

# Verify symlink target exists
readlink -f net/aws.tf
# Output: /full/path/to/common-files/aws.tf
```

### Broken Symlink Detection
```bash
# Find broken symlinks
find . -type l ! -exec test -e {} \; -print
```

---

## Best Practices

### DO:
✅ Use symlinks for truly common configuration  
✅ Keep common files generic and reusable  
✅ Document which stages need which common files  
✅ Version control symlinks (Git tracks them)  
✅ Use relative paths for symlinks (portability)

### DON'T:
❌ Put stage-specific logic in common files  
❌ Modify common files for one stage's needs  
❌ Use absolute paths in symlinks  
❌ Copy common files instead of symlinking  
❌ Create circular dependencies between stages

---

## Troubleshooting

### Issue: "No such file or directory" when running Terraform
**Cause**: Broken symlink or common file doesn't exist  
**Solution**:
```bash
# Check symlink
ls -la stage/aws.tf

# Recreate if broken
cd stage/
rm aws.tf
ln -s ../common-files/aws.tf aws.tf
```

### Issue: "Parameter does not exist" error
**Cause**: SSM parameter not created by previous stage  
**Solution**:
```bash
# Verify parameter exists
aws ssm get-parameter --name /workshop/tf-eks/eks-vpc

# Check if previous stage completed successfully
cd tf-setup && terraform output
cd net && terraform output
```

### Issue: Provider version conflicts
**Cause**: Stage has local provider definition overriding common file  
**Solution**: Remove local provider definition, use symlinked `aws.tf`

### Issue: Variable not defined
**Cause**: Stage missing `vars-main.tf` symlink  
**Solution**:
```bash
cd stage/
ln -s ../common-files/vars-main.tf vars-main.tf
```

---

## Extending Common Files

### Adding a New SSM Parameter Data Source

1. **Add parameter to source stage** (e.g., in `net/ssm-params-net.tf`):
```terraform
resource "aws_ssm_parameter" "new_param" {
  name  = "/workshop/tf-eks/new-param"
  value = "some-value"
}
```

2. **Add data source to appropriate common file**:
```terraform
# In common-files/data-params-net.tf
data "aws_ssm_parameter" "new_param" {
  name = "/workshop/tf-eks/new-param"
}
```

3. **Use in downstream stages**:
```terraform
# In cluster/addons/etc.
resource "aws_example" "test" {
  value = data.aws_ssm_parameter.new_param.value
}
```

### Adding a New Common Variable

1. **Add to `common-files/vars-main.tf`**:
```terraform
variable "new_variable" {
  description = "Description of new variable"
  type        = string
  default     = "default-value"
}
```

2. **Variable automatically available in all stages** with symlink

---

## File Dependency Matrix

| Common File | tf-setup | net | cluster | nodepool | addons | observ |
|-------------|----------|-----|---------|----------|--------|--------|
| aws.tf | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| aws-data.tf | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| vars-main.tf | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| data-params-setup.tf | ❌ | ✓ | ✓ | ✓ | ✓ | ✓ |
| data-params-net.tf | ❌ | ❌ | ✓ | ✓ | ✓ | ❌ |
| data-params-cluster.tf | ❌ | ❌ | ❌ | ✓ | ✓ | ✓ |
| data-params-iam.tf | ❌ | ❌ | ❌ | ✓ | ✓ | ❌ |
| var-karpenter-version.tf | ❌ | ❌ | ❌ | ✓ | ✓ | ❌ |

✓ = Symlinked and used  
❌ = Not applicable (dependencies don't exist yet or not needed)

---

## Related Documentation

- **tf-setup Stage**: See `docs/README-tf-setup.md` for SSM parameter creation
- **Build Scripts**: See `.aws-staff/build-all.sh` for stage execution order
- **Backend Generation**: See `tf-setup/gen-backend.sh` for backend file creation

---

## Summary

The `common-files` directory is a critical component of the infrastructure's DRY architecture. By centralizing provider configuration, variable definitions, and SSM parameter data sources, it ensures consistency across all stages while reducing maintenance overhead. The symlink pattern allows each stage to access exactly the configuration it needs without duplication or drift.
