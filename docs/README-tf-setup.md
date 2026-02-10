# tf-setup Stage Documentation

## Overview

The `tf-setup` stage is the foundational first step in the EKS workshop infrastructure deployment. It creates the core AWS resources needed for managing Terraform state and establishes shared configuration parameters that subsequent stages will consume.

**Execution Time**: Part of the ~40 minute total build process  
**Dependencies**: None (first stage to run)  
**Outputs**: S3 bucket, KMS key, SSM parameters, backend configuration files

---

## Purpose

This stage accomplishes three critical tasks:

1. **State Management Infrastructure**: Creates an S3 bucket with encryption and versioning for storing Terraform state files
2. **Shared Configuration**: Generates SSM parameters that other stages reference for consistent configuration
3. **Backend Generation**: Dynamically creates backend configuration files for all subsequent stages

---

## Architecture Components

### 1. KMS Encryption Key (`kms.tf`)

Creates a KMS key for encrypting the S3 bucket containing Terraform state.

```terraform
resource "aws_kms_key" "ekskey"
```

**Purpose**: Ensures state files are encrypted at rest  
**Output**: `keyid` - Used by S3 bucket and stored in SSM

---

### 2. Random ID Generator (`rand.tf`)

Generates a unique 8-byte random identifier used throughout the build.

```terraform
resource "random_id" "id1" {
  byte_length = 8
}
```

**Purpose**: Creates unique resource names to avoid conflicts  
**Output**: `tfid` - 16-character hex string  
**Usage**: Appended to S3 bucket name, stored in SSM for other stages

---

### 3. S3 State Bucket (`s3-bucket.tf`)

Creates a secure S3 bucket for storing Terraform state files.

**Features**:
- **Naming**: `tf-state-workshop-{random_id}`
- **Encryption**: KMS encryption using the generated key
- **Versioning**: Enabled for state file history
- **Public Access**: Completely blocked
- **Force Destroy**: Enabled (for workshop cleanup - not production practice)

**Resources Created**:
- `aws_s3_bucket.terraform_state` - Main bucket
- `aws_s3_bucket_server_side_encryption_configuration` - KMS encryption
- `aws_s3_bucket_versioning` - Version control
- `aws_s3_bucket_public_access_block` - Security hardening

---

### 4. SSM Parameter Store (`ssm-params-setup.tf`)

Creates 7 SSM parameters that serve as a configuration registry for all stages.

| Parameter Path | Value | Purpose |
|---------------|-------|---------|
| `/workshop/tf-eks/id` | Random hex ID | Unique identifier for resources |
| `/workshop/tf-eks/keyid` | KMS key ID | Encryption key reference |
| `/workshop/tf-eks/keyarn` | KMS key ARN | Full ARN for IAM policies |
| `/workshop/tf-eks/region` | AWS region | Deployment region |
| `/workshop/tf-eks/cluster-name` | Cluster name | EKS cluster identifier |
| `/workshop/tf-eks/bucket-name` | S3 bucket name | State bucket reference |
| `/workshop/tf-eks/eks-version` | EKS version | Kubernetes version |

**Tag**: All parameters tagged with `workshop = "tf-eks-workshop"`

---

### 5. Backend Generator (`null_resource.tf` + `gen-backend.sh`)

Orchestrates the creation of backend configuration files after the S3 bucket is ready.

#### Null Resource Trigger

```terraform
resource "null_resource" "gen_backend" {
  triggers = {
    always_run = timestamp()
  }
  depends_on = [aws_s3_bucket_server_side_encryption_configuration.terraform_state]
  provisioner "local-exec" {
    when    = create
    command = "./gen-backend.sh"
  }
}
```

**Behavior**:
- Waits for S3 bucket encryption to be configured
- Sleeps 6 seconds to ensure AWS consistency
- Executes `gen-backend.sh` script

---

## gen-backend.sh Script Analysis

### Purpose
Generates standardized backend configuration files for all infrastructure stages.

### Execution Flow

#### 1. Terraform Plugin Cache Setup
```bash
mkdir -p $HOME/.terraform.d/plugin-cache
cp dot-terraform.rc $HOME/.terraformrc
```
- Creates plugin cache directory to speed up provider downloads
- Copies configuration to user's home directory

#### 2. Extract Terraform Outputs
```bash
reg=`terraform output -json region | jq -r .[]`
s3b=`terraform output -json s3_bucket | jq -r .[]`
```
- Retrieves region and S3 bucket name from current state
- Uses `jq` to parse JSON output

#### 3. Generate Backend Files

Creates backend configuration for these stages:
- `tf-setup`
- `net`
- `cluster`
- `nodepool`
- `addons`
- `observ`

Each file (`generated/backend-{stage}.tf`) contains:

**Terraform Block**:
- Version constraint: `> 1.12.0`
- Provider versions (AWS 5.100.0, Kubernetes 2.24.0, Helm 2.17.0, kubectl 1.14+)

**Backend Configuration**:
```terraform
backend "s3" {
  bucket = "tf-state-workshop-{random_id}"
  key = "terraform/{stage}.tfstate"
  region = "{region}"
  use_lockfile = true
  encrypt = true
}
```

**Provider Configuration**:
```terraform
provider "aws" {
  region = var.region
  shared_credentials_files = ["~/.aws/credentials"]
}
```

#### 4. Format Code
```bash
terraform fmt --recursive
```
Ensures all generated files follow Terraform formatting standards.

---

## Variables (`vars-main.tf`)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `region` | string | `eu-west-1` | AWS deployment region |
| `profile` | string | `default` | AWS credentials profile |
| `cluster-name` | string | `eks-workshop` | EKS cluster name |
| `eks_version` | string | `1.33` | Kubernetes version |
| `no-output` | string | `secret` | Sensitive placeholder (unused) |

**Environment Override**: Variables can be set via `TF_VAR_` environment variables

---

## Provider Configuration (`aws.tf`)

### Terraform Requirements
- **Minimum Version**: 1.12.0
- **AWS Provider**: 5.100.0 (locked)
- **Additional Providers**: null, external, kubernetes, helm, kubectl, local

### AWS Provider
```terraform
provider "aws" {
  region = var.region
  shared_credentials_files = ["~/.aws/credentials"]
}
```

**Authentication**: Uses local AWS credentials file  
**Region**: Configurable via variable (default: eu-west-1)

---

## Data Sources (`aws-data.tf`)

Retrieves AWS account and region information:

```terraform
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "az" {
  state = "available"
}
```

**Usage**: Provides context about the deployment environment

---

## Outputs (`output.tf`)

| Output | Value | Description |
|--------|-------|-------------|
| `region` | S3 bucket region | Deployment region |
| `s3_bucket` | Bucket name | State bucket identifier |
| `keyid` | KMS key ID | Encryption key |
| `tfid` | Random hex | Unique identifier |

---

## Directory Structure

```
tf-setup/
├── aws.tf                    # Provider and version configuration
├── aws-data.tf              # AWS data sources
├── vars-main.tf             # Input variables
├── kms.tf                   # KMS key for encryption
├── rand.tf                  # Random ID generator
├── s3-bucket.tf             # State bucket with security
├── ssm-params-setup.tf      # Configuration parameters
├── null_resource.tf         # Backend generation trigger
├── output.tf                # Output values
├── gen-backend.sh           # Backend file generator script
├── dot-terraform.rc         # Plugin cache configuration
└── generated/               # Generated backend files (created by script)
    ├── backend-tf-setup.tf
    ├── backend-net.tf
    ├── backend-cluster.tf
    ├── backend-nodepool.tf
    ├── backend-addons.tf
    └── backend-observ.tf
```

---

## Execution Sequence

When `build-stage.sh tf-setup` runs:

1. **Clean**: Removes `.terraform*` and `backend.tf`
2. **Init**: `terraform init` (no backend yet - local state)
3. **Plan**: Analyzes resources to create
4. **Apply**: Creates resources in this order:
   - Random ID
   - KMS key
   - S3 bucket with encryption/versioning
   - SSM parameters
   - Null resource triggers `gen-backend.sh`
5. **Script Execution**:
   - Sets up plugin cache
   - Extracts outputs (region, bucket name)
   - Generates backend files for all stages
   - Formats Terraform code
6. **Validation**: Confirms expected resources in state

---

## Key Design Decisions

### Why Local State Initially?
The first run uses local state because the S3 backend doesn't exist yet. Subsequent stages use the generated backend configurations.

### Why Generate Backend Files?
- **DRY Principle**: Single source of truth for bucket name and region
- **Consistency**: All stages use identical provider versions
- **Automation**: No manual configuration needed

### Why SSM Parameters?
- **Cross-Stage Communication**: Later stages read these values
- **Centralized Config**: Single place to update shared values
- **AWS Native**: No external configuration management needed

### Why Force Destroy on S3?
Workshop/demo environment only. Allows complete cleanup. **Never use in production**.

---

## Dependencies for Other Stages

All subsequent stages depend on:

1. **Backend Files**: `generated/backend-{stage}.tf` copied to stage directory
2. **SSM Parameters**: Read via data sources in other stages
3. **S3 Bucket**: Stores state for all stages

---

## Common Issues

### Issue: "no terraform output variables"
**Cause**: Script runs before apply completes  
**Solution**: 6-second sleep in null_resource, but may need adjustment

### Issue: Backend file not found
**Cause**: `gen-backend.sh` failed or didn't run  
**Solution**: Check null_resource execution logs

### Issue: S3 bucket already exists
**Cause**: Random ID collision (extremely rare)  
**Solution**: Destroy and re-run to generate new ID

---

## Security Considerations

✅ **Good Practices**:
- KMS encryption for state files
- S3 versioning enabled
- Public access completely blocked
- Credentials from local file (not hardcoded)

⚠️ **Workshop-Only Practices** (don't use in production):
- `force_destroy = true` on S3 bucket
- No MFA delete requirement
- No bucket lifecycle policies
- No cross-region replication

---

## Testing

After successful execution, verify:

```bash
# Check S3 bucket exists
aws s3 ls | grep tf-state-workshop

# Check SSM parameters
aws ssm get-parameters-by-path --path /workshop/tf-eks/

# Check generated files
ls -la tf-setup/generated/backend-*.tf

# Verify KMS key
aws kms list-keys
```

---

## Cleanup

To destroy this stage (after destroying all dependent stages):

```bash
cd tf-setup
terraform destroy
```

**Note**: Must destroy other stages first due to state dependencies.

---

## Related Files

- **Build Scripts**: `.aws-staff/build-all.sh`, `.aws-staff/build-stage.sh`
- **Common Files**: `common-files/` directory (referenced by other stages)
- **Next Stage**: `net/` (network infrastructure)
