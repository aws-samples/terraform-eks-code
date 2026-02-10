# net Stage Documentation

## Overview

The `net` stage creates the network infrastructure for the EKS workshop, including VPC, subnets, VPC peering, security groups, VPC endpoints, and Route53 private hosted zone. This stage establishes the networking foundation that the EKS cluster will be deployed into.

**Execution Time**: Part of the ~40 minute total build process  
**Dependencies**: tf-setup stage (requires SSM parameters)  
**Outputs**: VPC ID, subnet IDs, route table IDs, security groups, VPC endpoints  
**Next Stage**: cluster (deploys EKS into this network)

---

## Architecture Overview

### Network Design

```
┌─────────────────────────────────────────────────────────────┐
│ Default VPC (AWS Managed)                                   │
│ - VSCode/Cloud9 Instance                                    │
│ - Development Tools                                         │
└────────────────┬────────────────────────────────────────────┘
                 │ VPC Peering
                 │
┌────────────────▼────────────────────────────────────────────┐
│ EKS VPC (10.141.0.0/16)                                     │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Public Subnets (10.141.48.0/24, 49, 50)             │  │
│  │ - NAT Gateway                                        │  │
│  │ - Load Balancers                                     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Private Subnets (100.65.0.0/18 - Secondary CIDR)    │  │
│  │ - EKS Worker Nodes                                   │  │
│  │ - Application Pods                                   │  │
│  │ - Karpenter-managed nodes                            │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Intra Subnets (10.141.52.0/24, 53, 54)              │  │
│  │ - EKS Control Plane ENIs                             │  │
│  │ - VPC Endpoints                                      │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  VPC Endpoints: S3, ECR, EC2, SSM, Logs, Secrets Manager   │
└──────────────────────────────────────────────────────────────┘
```

---

## Key Design Decisions

### 1. Dual CIDR Blocks
**Primary CIDR**: `10.141.0.0/16` - Used for public and intra subnets  
**Secondary CIDR**: `100.65.0.0/16` - Used for private subnets (worker nodes)

**Why?**
- Provides large IP space for pod networking (100.64.0.0/10 is RFC 6598 shared address space)
- Separates node IPs from infrastructure IPs
- Allows for future expansion without renumbering

### 2. Three Subnet Types

#### Public Subnets (10.141.48-50.0/24)
- Internet Gateway attached
- NAT Gateway deployed here
- Load balancers for public-facing services
- Tagged for ELB auto-discovery: `kubernetes.io/role/elb = 1`

#### Private Subnets (100.65.0.0/18 per AZ)
- NAT Gateway for outbound internet
- EKS worker nodes
- Application pods
- Tagged for internal ELB: `kubernetes.io/role/internal-elb = 1`
- Tagged for Karpenter: `karpenter.sh/discovery = eks-workshop`

#### Intra Subnets (10.141.52-54.0/24)
- No internet access (isolated)
- EKS control plane ENIs
- VPC endpoints
- Reduces data transfer costs

### 3. VPC Peering with Default VPC
- Allows VSCode/Cloud9 instance to access EKS cluster
- Enables kubectl commands from development environment
- Bidirectional routing configured

### 4. VPC Endpoints
- Interface endpoints for AWS services (ECR, EC2, SSM, etc.)
- Gateway endpoint for S3
- Reduces NAT Gateway costs
- Improves security (traffic stays within AWS network)
- Deployed in intra subnets

---

## File-by-File Breakdown

### Core Infrastructure

#### vpc.tf
**Purpose**: Creates the main VPC using the AWS VPC Terraform module

**Key Resources**:
- VPC with primary and secondary CIDR blocks
- 3 availability zones
- Public, private, and intra subnets
- Single NAT Gateway (cost optimization)
- VPC Flow Logs to CloudWatch
- DNS hostnames and DNS support enabled

**Subnet Calculations**:
```terraform
# Private: 100.65.0.0/18, 100.65.64.0/18, 100.65.128.0/18
private_subnets = [for k, v in local.azs : cidrsubnet(element(local.secondary_cidr_blocks, 0), 2, k)]

# Public: 10.141.48.0/24, 10.141.49.0/24, 10.141.50.0/24
public_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

# Intra: 10.141.52.0/24, 10.141.53.0/24, 10.141.54.0/24
intra_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]
```

**Tags**:
- Kubernetes ELB discovery tags
- Karpenter discovery tags
- Workshop identification tags

**Flow Logs**:
- Retention: 7 days
- Destination: CloudWatch Logs
- Custom format with detailed network information

#### locals.tf
**Purpose**: Defines local variables used throughout the stage

**Variables**:
- `name`: Cluster name from SSM parameter
- `cluster_version`: EKS version from SSM parameter
- `vpc_cidr`: Primary CIDR block (10.141.0.0/16)
- `secondary_cidr_blocks`: Secondary CIDR for nodes (100.65.0.0/16)
- `azs`: First 3 availability zones in the region
- `tags`: Standard tags for all resources

**Why 100.65.0.0/16?**
- Part of RFC 6598 shared address space (100.64.0.0/10)
- Designed for carrier-grade NAT
- Large address space for pod networking
- Unlikely to conflict with on-premises networks

---

### VPC Peering

#### def-peering.tf
**Purpose**: Creates VPC peering connection between default VPC and EKS VPC

**Resource**: `aws_vpc_peering_connection.def-peer`
- Peers default VPC with EKS VPC
- Auto-accept enabled (same account)
- Allows VSCode/Cloud9 to access cluster

**Output**: Peering connection ID for route configuration

#### def-route-add.tf
**Purpose**: Adds route in default VPC to reach EKS VPC

**Route**: Default VPC → EKS VPC CIDR via peering connection

#### eks-route-add.tf
**Purpose**: Adds routes in EKS VPC to reach default VPC

**Routes**:
1. Private route table → Default VPC CIDR
2. Intra route table → Default VPC CIDR

**Why both?**
- Private subnets: Worker nodes need to reach default VPC
- Intra subnets: Control plane ENIs need connectivity

---

### Security Groups

#### sg-def-rule-eks.tf
**Purpose**: Configures default security group for EKS VPC

**Rules**:
- Ingress: All traffic from self (resources in same SG)
- Egress: All traffic to internet

**Best Practice**: Default SG should be restrictive; this is for workshop convenience

#### sg-rule-def.tf
**Purpose**: Adds ingress rules to VSCode/Cloud9 security group

**Rules Added**:
- Port 443 from EKS VPC (HTTPS)
- Port 22 from EKS VPC (SSH)
- Port 8080 from anywhere (application access)
- Port 80 from anywhere (HTTP)

**Why?**
- Allows EKS pods to communicate with development instance
- Enables testing applications from browser
- Port 8080/80 open for workshop demos (not production practice)

#### data-sg-vscode-instance.tf
**Purpose**: Discovers VSCode/Cloud9 instance and its security group

**Data Sources**:
- `aws_instance.c9inst`: Finds instance tagged "VSCodeServer"
- `aws_security_group.c9sg`: Gets the instance's security group
- `aws_iam_instance_profile.c9ip`: Gets IAM instance profile

**Usage**: Referenced by security group rules

---

### VPC Endpoints

#### vpc-endpoints.tf
**Purpose**: Creates VPC endpoints for AWS services

**Module**: `terraform-aws-modules/vpc/aws//modules/vpc-endpoints`

**Endpoints Created**:

| Service | Type | Purpose |
|---------|------|---------|
| S3 | Gateway | ECR image layers, Terraform state |
| ECR API | Interface | Pull container images |
| ECR DKR | Interface | Docker registry operations |
| EC2 | Interface | Instance metadata, EBS operations |
| Autoscaling | Interface | Karpenter node scaling |
| STS | Interface | IAM role assumption (IRSA) |
| Logs | Interface | CloudWatch Logs |
| SSM | Interface | Systems Manager operations |
| SSM Messages | Interface | Session Manager |
| EC2 Messages | Interface | SSM Agent communication |
| Secrets Manager | Interface | Application secrets |
| GuardDuty Data | Interface | Security findings |
| Grafana | Interface | Observability |

**Security Group**:
- Ingress: HTTPS from both VPC CIDRs
- Egress: HTTPS and SSH to internet

**Placement**: Intra subnets (cost optimization)

**Endpoint Policy**: Denies access from outside the VPC

**Benefits**:
- Reduced NAT Gateway data transfer costs
- Improved security (traffic doesn't leave AWS network)
- Better performance (lower latency)
- Required for private EKS clusters

---

### Route53

#### phz.tf
**Purpose**: Creates private hosted zone for internal DNS

**Zone Name Format**: `{account-id}.{random-id}.people.aws.dev`

**Example**: `123456789012.a1b2c3d4e5f6g7h8.people.aws.dev`

**Usage**:
- Internal service discovery
- Keycloak authentication
- Application DNS names

**Note**: Commented out SSM parameter (now in ssm-params-net.tf)

---

### Data Sources

#### data-defvpc.tf
**Purpose**: Retrieves default VPC information

**Data Source**: `aws_vpc.vpc-default`
- Finds the default VPC in the region
- Used for peering configuration

---

### SSM Parameters

#### ssm-params-net.tf
**Purpose**: Stores network configuration in SSM Parameter Store for downstream stages

**Parameters Created**:

| Parameter | Value | Used By |
|-----------|-------|---------|
| `/workshop/tf-eks/cicd-vpc` | VPC ID | Future CI/CD integration |
| `/workshop/tf-eks/eks-vpc` | VPC ID | cluster, nodepool, addons |
| `/workshop/tf-eks/eks-cidr` | VPC CIDR | Security group rules |
| `/workshop/tf-eks/cicd-cidr` | VPC CIDR | Peering rules |
| `/workshop/tf-eks/private_subnets` | Subnet IDs (JSON) | EKS cluster, node groups |
| `/workshop/tf-eks/intra_subnets` | Subnet IDs (JSON) | Control plane ENIs |
| `/workshop/tf-eks/private_rtb` | Route table ID | Route additions |
| `/workshop/tf-eks/intra_rtb` | Route table ID | Route additions |
| `/workshop/tf-eks/public_rtb` | Route table ID | Future use |
| `/workshop/tf-eks/phz-id` | Hosted zone ID | DNS records |

**Note**: Database subnet parameters commented out (not used in workshop)

**Value Format**:
- Single values: String
- Lists: JSON-encoded array (use `jsonencode()`)

**Usage in Other Stages**:
```terraform
# In cluster stage
data "aws_ssm_parameter" "eks-vpc" {
  name = "/workshop/tf-eks/eks-vpc"
}

resource "aws_eks_cluster" "main" {
  vpc_config {
    subnet_ids = jsondecode(data.aws_ssm_parameter.private_subnets.value)
  }
}
```

---

### Variables

#### vars-domain.tf
**Purpose**: Defines domain name for private hosted zone

**Variable**: `dn`
- Default: `people.aws.dev`
- Type: string
- Used in Route53 zone name

**Commented Alternative**: `testdomain.local` (for testing)

---

## Symlinked Files

These files are symlinked from `common-files/`:

- **aws-data.tf**: AWS account and region data sources
- **backend-net.tf**: S3 backend configuration (generated by tf-setup)
- **data-params-setup.tf**: Setup stage SSM parameters
- **vars-main.tf**: Common variables (region, cluster-name, etc.)

---

## Resource Dependencies

```
tf-setup (SSM params)
    ↓
locals.tf (reads SSM params)
    ↓
vpc.tf (creates VPC)
    ↓
    ├─→ vpc-endpoints.tf (uses VPC ID, subnets)
    ├─→ def-peering.tf (uses VPC ID)
    │       ↓
    │   def-route-add.tf (uses peering ID)
    │   eks-route-add.tf (uses peering ID, route tables)
    │
    ├─→ sg-def-rule-eks.tf (uses VPC ID)
    ├─→ phz.tf (creates hosted zone)
    └─→ ssm-params-net.tf (stores outputs)
            ↓
        cluster stage
```

---

## IP Address Allocation

### Primary CIDR (10.141.0.0/16)
- **Total IPs**: 65,536
- **Public Subnets**: 10.141.48.0/24 - 10.141.50.0/24 (768 IPs)
- **Intra Subnets**: 10.141.52.0/24 - 10.141.54.0/24 (768 IPs)
- **Reserved**: Remaining space for future use

### Secondary CIDR (100.65.0.0/16)
- **Total IPs**: 65,536
- **Private Subnets**: 
  - AZ1: 100.65.0.0/18 (16,384 IPs)
  - AZ2: 100.65.64.0/18 (16,384 IPs)
  - AZ3: 100.65.128.0/18 (16,384 IPs)
- **Total Private**: 49,152 IPs for nodes and pods

**Capacity**:
- Supports thousands of nodes
- Sufficient for large-scale pod deployments
- Room for Karpenter auto-scaling

---

## Cost Optimization Features

### 1. Single NAT Gateway
- **Savings**: ~$90/month vs. 3 NAT Gateways
- **Trade-off**: Single point of failure
- **Acceptable for**: Workshop/dev environments
- **Production**: Use one NAT Gateway per AZ

### 2. VPC Endpoints
- **Savings**: Reduces NAT Gateway data transfer costs
- **Cost**: ~$7/month per endpoint
- **Break-even**: High ECR/S3 usage
- **Benefit**: Improved security and performance

### 3. Gateway Endpoint for S3
- **Cost**: Free
- **Benefit**: No data transfer charges for S3 access

### 4. Intra Subnets for Endpoints
- **Savings**: No NAT Gateway charges for endpoint traffic
- **Benefit**: Isolated from internet

---

## Security Features

### 1. Private Subnets for Nodes
- Worker nodes have no public IPs
- Internet access via NAT Gateway only
- Reduces attack surface

### 2. VPC Endpoints
- Traffic doesn't traverse internet
- Endpoint policies restrict access
- Private DNS enabled

### 3. VPC Flow Logs
- Network traffic monitoring
- Security analysis
- Troubleshooting
- 7-day retention

### 4. Security Group Segmentation
- Default SG for VPC resources
- Separate SG for VPC endpoints
- VSCode/Cloud9 SG modifications

### 5. Network ACLs
- Managed by VPC module
- Default ACLs allow all (stateless)
- Security groups provide stateful filtering

---

## Testing and Verification

### After Deployment

```bash
# Verify VPC created
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eks-workshop"

# Check subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"

# Verify VPC peering
aws ec2 describe-vpc-peering-connections

# Check VPC endpoints
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=<vpc-id>"

# Verify SSM parameters
aws ssm get-parameters-by-path --path /workshop/tf-eks/ --recursive

# Test connectivity from VSCode/Cloud9
ping 10.141.48.1  # Should work via peering

# Check Route53 zone
aws route53 list-hosted-zones
```

---

## Common Issues

### Issue: NAT Gateway creation timeout
**Cause**: AWS service delay  
**Solution**: Retry terraform apply

### Issue: VPC endpoint creation fails
**Cause**: Service not available in region  
**Solution**: Check service availability, remove unavailable endpoints

### Issue: Peering connection not working
**Cause**: Route tables not updated  
**Solution**: Verify routes in both VPCs

### Issue: SSM parameter not found in next stage
**Cause**: Net stage didn't complete successfully  
**Solution**: Check terraform output, verify parameters exist

### Issue: Subnet IP exhaustion
**Cause**: Too many pods/nodes  
**Solution**: Increase subnet size or add more subnets

---

## Extending the Network

### Adding Database Subnets

Uncomment in `vpc.tf`:
```terraform
database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 56)]
```

Uncomment in `ssm-params-net.tf`:
```terraform
resource "aws_ssm_parameter" "database_subnets" {
  name  = "/workshop/tf-eks/database_subnets"
  value = jsonencode(module.vpc.database_subnets)
}
```

### Adding More VPC Endpoints

In `vpc-endpoints.tf`, add to the `endpoints` map:
```terraform
endpoints = merge({
  # ... existing endpoints ...
  },
  { for service in toset(["new-service"]) :
    replace(service, ".", "_") => {
      service             = service
      subnet_ids          = module.vpc.intra_subnets
      private_dns_enabled = true
      tags                = { Name = "${local.name}-${service}" }
    }
  }
)
```

### Changing to Multi-NAT Gateway

In `vpc.tf`:
```terraform
enable_nat_gateway = true
single_nat_gateway = false  # Change to false
one_nat_gateway_per_az = true  # Add this line
```

**Cost Impact**: +$64/month per additional NAT Gateway

---

## Best Practices

### DO:
✅ Use VPC endpoints for frequently accessed AWS services  
✅ Enable VPC Flow Logs for security monitoring  
✅ Use private subnets for worker nodes  
✅ Tag subnets for Kubernetes auto-discovery  
✅ Use secondary CIDR for large IP space  
✅ Document CIDR allocations

### DON'T:
❌ Use single NAT Gateway in production  
❌ Open security groups to 0.0.0.0/0 unnecessarily  
❌ Forget to update route tables after peering  
❌ Use overlapping CIDR blocks  
❌ Deploy control plane ENIs in public subnets  
❌ Skip VPC Flow Logs

---

## Related Documentation

- **tf-setup Stage**: See `docs/README-tf-setup.md` for SSM parameter creation
- **common-files**: See `docs/README-common-files.md` for shared configuration
- **cluster Stage**: Next stage that uses this network infrastructure
- **AWS VPC Module**: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws

---

## Summary

The net stage creates a production-ready network architecture with:
- Dual CIDR blocks for scalability
- Three subnet types for proper segmentation
- VPC endpoints for cost and security optimization
- VPC peering for development access
- Comprehensive tagging for Kubernetes integration
- SSM parameters for cross-stage communication

This network foundation supports the EKS cluster deployment in the next stage while maintaining security, scalability, and cost efficiency.
