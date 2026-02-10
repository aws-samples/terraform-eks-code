# nodepool Stage Documentation

## Overview

The `nodepool` stage configures Karpenter node provisioning for the EKS cluster, including NodeClass definitions, NodePool specifications, storage classes, and a test deployment. This stage enables automatic, efficient node scaling based on pod requirements.

**Execution Time**: ~2-3 minutes (part of the ~40 minute total build)  
**Dependencies**: tf-setup (SSM parameters), net (VPC/subnets), cluster (EKS cluster, IAM roles)  
**Outputs**: Karpenter NodeClass, NodePool, StorageClass, test deployment  
**Next Stage**: addons (installs cluster add-ons and applications)

---

## Architecture Overview

### Karpenter Node Provisioning

```
┌─────────────────────────────────────────────────────────────────┐
│ Kubernetes Scheduler                                             │
│ - Detects unschedulable pods                                    │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ Karpenter Controller                                             │
│ - Reads NodePool requirements                                   │
│ - Selects optimal instance type                                 │
│ - Provisions EC2 instances                                      │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ NodeClass (mynodeclass)                                          │
│ - IAM Role: eks-node-role                                       │
│ - Subnets: Private subnets (100.65.0.0/16)                     │
│ - Security Group: Cluster primary SG                            │
│ - Ephemeral Storage: 80Gi gp3                                   │
│ - SNAT Policy: Random                                            │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ NodePool (my-node-pool2)                                         │
│ - Instance Categories: c, m, r (compute, memory, general)       │
│ - Instance Sizes: 4, 8, 16, 32 vCPUs                           │
│ - Architecture: amd64                                            │
│ - Generation: > 5 (modern instances)                            │
│ - Capacity Types: on-demand, spot                               │
│ - Limits: 1000 CPUs, 1000Gi memory                             │
│ - Disruption: Consolidation, expiration, budgets                │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ EC2 Instances (Worker Nodes)                                    │
│ - Launched in private subnets                                   │
│ - Automatically join EKS cluster                                │
│ - Run application pods                                          │
└──────────────────────────────────────────────────────────────────┘
```

---

## Key Features

### 1. Karpenter NodeClass
- **Purpose**: Defines infrastructure configuration for nodes
- **IAM Role**: Uses cluster-created node role
- **Network**: Private subnets with internal ELB tag
- **Security**: Cluster primary security group
- **Storage**: 80Gi gp3 ephemeral storage with 3000 IOPS

### 2. Karpenter NodePool
- **Purpose**: Defines scheduling requirements and constraints
- **Instance Selection**: Flexible (c, m, r families, 4-32 vCPUs)
- **Capacity Types**: Both on-demand and spot instances
- **Disruption Policies**: Automatic consolidation and expiration
- **Limits**: 1000 CPUs and 1000Gi memory total

### 3. Storage Class
- **Type**: gp3 EBS volumes
- **Encryption**: Enabled by default
- **Binding**: WaitForFirstConsumer (topology-aware)
- **Default**: Set as default storage class

### 4. Test Deployment
- **Name**: inflate
- **Purpose**: Test Karpenter node provisioning
- **Initial Replicas**: 0 (scale up to test)
- **Resource Request**: 1Gi memory per pod

---

## File-by-File Breakdown

### NodeClass Configuration

#### nodeclass.tf
**Purpose**: Defines the infrastructure template for Karpenter-provisioned nodes

**Key Configuration**:

##### API Version and Kind
```yaml
apiVersion: eks.amazonaws.com/v1
kind: NodeClass
metadata:
  name: mynodeclass
```
- **API Group**: `eks.amazonaws.com` (EKS-specific)
- **Version**: v1
- **Name**: `mynodeclass` (referenced by NodePool)

##### IAM Role
```yaml
role: ${data.aws_ssm_parameter.eks-node-role-name.value}
```
- **Source**: Node role created by cluster stage
- **Permissions**: EC2, ECR, EKS, CloudWatch
- **Purpose**: Allows nodes to join cluster and run workloads

##### Subnet Selection
```yaml
subnetSelectorTerms:
  - tags:
      kubernetes.io/role/internal-elb: "1"
```
- **Selection Method**: Tag-based
- **Tag**: `kubernetes.io/role/internal-elb: "1"`
- **Matches**: Private subnets from net stage
- **Alternative**: Can use direct subnet IDs

**Why This Tag?**
- Private subnets are tagged during VPC creation
- Ensures nodes are placed in private subnets only
- Automatic subnet discovery across AZs

##### Security Group Selection
```yaml
securityGroupSelectorTerms:
  - id: ${data.aws_ssm_parameter.cluster-sg.value}
```
- **Selection Method**: Direct ID reference
- **Security Group**: Cluster primary security group
- **Source**: Created by EKS cluster
- **Purpose**: Control-plane-to-node communication

**Alternative Methods**:
```yaml
# By tag
- tags:
    Name: my-security-group

# By name
- name: "my security group name"
```

##### SNAT Policy
```yaml
snatPolicy: Random
```
- **Options**: `Random` or `Disabled`
- **Random**: Distributes SNAT across available IPs
- **Disabled**: No source NAT (requires custom networking)
- **Default**: Random

##### Network Policy
```yaml
networkPolicy: DefaultAllow
```
- **Options**: `DefaultAllow` or `DefaultDeny`
- **DefaultAllow**: All traffic allowed by default
- **DefaultDeny**: Requires explicit network policies
- **Default**: DefaultAllow

##### Network Policy Event Logs
```yaml
networkPolicyEventLogs: Disabled
```
- **Options**: `Enabled` or `Disabled`
- **Purpose**: Log network policy decisions
- **Use Case**: Debugging network policies
- **Default**: Disabled

##### Ephemeral Storage
```yaml
ephemeralStorage:
  size: "80Gi"
  iops: 3000
  throughput: 125
```
- **Size**: 80Gi (range: 1-59000Gi)
- **IOPS**: 3000 (range: 3000-16000)
- **Throughput**: 125 MB/s (range: 125-1000)
- **Volume Type**: gp3 (implied)

**Why 80Gi?**
- Sufficient for container images and logs
- Balance between cost and functionality
- Can be adjusted based on workload needs

##### Tags
```yaml
tags:
  Environment: "production"
  Team: "platform"
  Name: "EKS Auto Workshop"
```
- **Purpose**: EC2 instance tagging
- **Use Cases**: Cost allocation, resource management
- **Propagation**: Applied to all provisioned instances

---

### NodePool Configuration

#### nodepool2.tf
**Purpose**: Defines scheduling requirements and node lifecycle policies

**Data Source**:
```terraform
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
```
- **Purpose**: Get available AZs for the region
- **Filter**: Excludes Local Zones and Wavelength Zones
- **Usage**: Passed to NodePool zone requirements

**Key Configuration**:

##### API Version and Kind
```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: my-node-pool2
```
- **API Group**: `karpenter.sh` (Karpenter-specific)
- **Version**: v1
- **Name**: `my-node-pool2`

##### Disruption Policies
```yaml
disruption:
  consolidationPolicy: WhenEmpty
  consolidateAfter: 30s
  expireAfter: 48h
  budgets:
    - nodes: "50%"
      schedule: "0 2 * * *"
      duration: "3h"
```

**Consolidation Policy**:
- **WhenEmpty**: Consolidate nodes when they become empty
- **After**: 30 seconds of being empty
- **Purpose**: Reduce costs by removing unused nodes

**Expiration**:
- **After**: 48 hours (2 days)
- **Purpose**: Rotate nodes for security updates
- **Behavior**: Gracefully drain and replace nodes

**Disruption Budgets**:
- **Limit**: 50% of nodes
- **Schedule**: Daily at 2am UTC (cron format)
- **Duration**: 3 hours
- **Purpose**: Controlled node rotation during maintenance window

##### Template Metadata
```yaml
template:
  metadata:
    labels:
      billing-team: my-team
```
- **Purpose**: Labels applied to all nodes
- **Use Cases**: Cost allocation, scheduling constraints
- **Propagation**: Visible in Kubernetes node labels

##### NodeClass Reference
```yaml
spec:
  nodeClassRef:
    group: eks.amazonaws.com
    kind: NodeClass
    name: mynodeclass
```
- **Links**: NodePool to NodeClass
- **Purpose**: Inherit infrastructure configuration

##### Instance Requirements

**Instance Category**:
```yaml
- key: "eks.amazonaws.com/instance-category"
  operator: In
  values: ["c", "m", "r"]
```
- **c**: Compute-optimized (CPU-intensive workloads)
- **m**: General-purpose (balanced compute/memory)
- **r**: Memory-optimized (memory-intensive workloads)

**Instance CPU**:
```yaml
- key: "eks.amazonaws.com/instance-cpu"
  operator: In
  values: ["4", "8", "16", "32"]
```
- **Range**: 4 to 32 vCPUs
- **Examples**: c5.xlarge (4), m5.2xlarge (8), r5.4xlarge (16)
- **Purpose**: Flexible sizing based on workload

**Availability Zones**:
```yaml
- key: "topology.kubernetes.io/zone"
  operator: In
  values: ${jsonencode(data.aws_availability_zones.available.names)}
```
- **Dynamic**: Uses all available AZs in region
- **Purpose**: High availability across zones

**Architecture**:
```yaml
- key: "kubernetes.io/arch"
  operator: In
  values: ["amd64"]
```
- **Architecture**: x86_64 (amd64)
- **Alternative**: arm64 (Graviton)
- **Reason**: Broader application compatibility

**Instance Generation**:
```yaml
- key: eks.amazonaws.com/instance-generation
  operator: Gt
  values: ["5"]
```
- **Constraint**: Greater than generation 5
- **Examples**: c6i, m6i, r6i (generation 6)
- **Purpose**: Modern instances with better performance/cost

**Capacity Type**:
```yaml
- key: "karpenter.sh/capacity-type"
  operator: In
  values: ["on-demand", "spot"]
```
- **On-Demand**: Guaranteed capacity, higher cost
- **Spot**: Up to 90% discount, can be interrupted
- **Strategy**: Karpenter chooses based on availability and cost

##### Resource Limits
```yaml
limits:
  cpu: "1000"
  memory: 1000Gi
```
- **CPU Limit**: 1000 cores total
- **Memory Limit**: 1000Gi total
- **Purpose**: Prevent runaway scaling
- **Scope**: Across all nodes in this NodePool

---

### Storage Configuration

#### storageclass.tf
**Purpose**: Defines default storage class for persistent volumes

**Configuration**:
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: auto-ebs-sc
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.eks.amazonaws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
  encrypted: "true"
```

**Key Features**:

##### Default Storage Class
```yaml
annotations:
  storageclass.kubernetes.io/is-default-class: "true"
```
- **Purpose**: Used when PVC doesn't specify storage class
- **Behavior**: Automatically selected for new PVCs

##### Provisioner
```yaml
provisioner: ebs.csi.eks.amazonaws.com
```
- **Driver**: EBS CSI driver
- **Purpose**: Creates EBS volumes dynamically
- **Requirement**: EBS CSI driver add-on must be installed

##### Volume Binding Mode
```yaml
volumeBindingMode: WaitForFirstConsumer
```
- **Behavior**: Delays volume creation until pod is scheduled
- **Benefit**: Ensures volume is in same AZ as pod
- **Alternative**: `Immediate` (creates volume immediately)

##### Volume Parameters
```yaml
parameters:
  type: gp3
  encrypted: "true"
```
- **Type**: gp3 (General Purpose SSD v3)
- **Encryption**: Enabled by default
- **Benefits**: Better performance/cost than gp2

**gp3 Advantages**:
- Baseline: 3000 IOPS, 125 MB/s throughput
- Cost: ~20% cheaper than gp2
- Scalability: Can increase IOPS/throughput independently

---

### Test Deployment

#### inflate.tf
**Purpose**: Test deployment to validate Karpenter node provisioning

**Configuration**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      terminationGracePeriodSeconds: 0
      containers:
        - name: inflate
          image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
          resources:
            requests:
              memory: 1Gi
          securityContext:
            allowPrivilegeEscalation: false
```

**Key Features**:

##### Initial Replicas
```yaml
replicas: 0
```
- **Purpose**: Doesn't create pods initially
- **Usage**: Scale up to test Karpenter
- **Command**: `kubectl scale deployment inflate --replicas=5`

##### Container Image
```yaml
image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
```
- **Image**: Minimal pause container
- **Size**: Very small (~1MB)
- **Purpose**: Holds resources without doing work

##### Resource Requests
```yaml
resources:
  requests:
    memory: 1Gi
```
- **Memory**: 1Gi per pod
- **Purpose**: Triggers node provisioning
- **Example**: 5 replicas = 5Gi memory needed

##### Termination Grace Period
```yaml
terminationGracePeriodSeconds: 0
```
- **Value**: 0 seconds
- **Purpose**: Immediate termination for testing
- **Production**: Use 30+ seconds for graceful shutdown

##### Security Context
```yaml
securityContext:
  allowPrivilegeEscalation: false
```
- **Purpose**: Security best practice
- **Behavior**: Prevents privilege escalation

**Testing Workflow**:
```bash
# Scale up to trigger node provisioning
kubectl scale deployment inflate --replicas=5

# Watch nodes being created
kubectl get nodes -w

# Watch pods being scheduled
kubectl get pods -l app=inflate -w

# Scale down to test consolidation
kubectl scale deployment inflate --replicas=0

# Watch nodes being removed (after 30s)
kubectl get nodes -w
```

---

## Symlinked Files

These files are symlinked from `common-files/`:

- **backend-nodepool.tf**: S3 backend configuration (generated by tf-setup)
- **data-params-cluster.tf**: Cluster stage SSM parameters (OIDC, endpoint, etc.)
- **vars-main.tf**: Common variables (region, cluster-name, etc.)

---

## Resource Dependencies

```
cluster (EKS cluster, node role)
    ↓
nodepool/nodeclass.tf (infrastructure template)
    ↓
nodepool/nodepool2.tf (scheduling requirements)
    ↓
nodepool/storageclass.tf (storage configuration)
    ↓
nodepool/inflate.tf (test deployment)
    ↓
addons stage
```

**Dependency Chain**:
1. NodeClass must exist before NodePool
2. NodePool must exist before inflate deployment
3. StorageClass is independent but needed for PVCs

---

## Karpenter Node Selection Logic

### How Karpenter Chooses Instances

1. **Pod Requirements**: Reads pod resource requests and node selectors
2. **NodePool Matching**: Finds NodePools that can satisfy requirements
3. **Instance Selection**: Evaluates instance types against requirements
4. **Cost Optimization**: Chooses cheapest instance that fits
5. **Availability**: Checks spot availability, falls back to on-demand
6. **Provisioning**: Launches instance and joins to cluster

### Example Scenarios

#### Scenario 1: Small Pod
```yaml
resources:
  requests:
    cpu: 500m
    memory: 1Gi
```
**Karpenter Choice**: c5.large (2 vCPU, 4Gi) or spot equivalent

#### Scenario 2: Large Pod
```yaml
resources:
  requests:
    cpu: 8
    memory: 32Gi
```
**Karpenter Choice**: r5.2xlarge (8 vCPU, 64Gi) or spot equivalent

#### Scenario 3: Multiple Small Pods
- **Pods**: 10 pods × 1Gi memory each
- **Strategy**: Bin-pack onto fewer, larger instances
- **Choice**: m5.2xlarge (8 vCPU, 32Gi) × 1-2 instances

---

## Disruption Policies Explained

### Consolidation
**Purpose**: Reduce costs by removing underutilized nodes

**Policy**: `WhenEmpty`
- Waits for node to be completely empty
- Waits additional 30 seconds
- Cordons and drains node
- Terminates instance

**Alternative**: `WhenUnderutilized`
- Consolidates when node is underutilized
- Moves pods to other nodes
- More aggressive cost optimization

### Expiration
**Purpose**: Rotate nodes for security and stability

**After**: 48 hours
- Ensures nodes get latest AMI updates
- Prevents long-running node issues
- Graceful drain and replacement

**Process**:
1. Node reaches 48-hour age
2. Karpenter cordons node
3. Drains pods to other nodes
4. Terminates old instance
5. Provisions new instance if needed

### Disruption Budgets
**Purpose**: Control rate of node disruption

**Configuration**:
- **Limit**: 50% of nodes
- **Schedule**: Daily at 2am UTC
- **Duration**: 3-hour window

**Behavior**:
- During window: Up to 50% of nodes can be disrupted
- Outside window: Normal disruption policies apply
- Prevents mass disruption during business hours

---

## Cost Optimization Strategies

### 1. Spot Instances
- **Savings**: Up to 90% vs on-demand
- **Risk**: Can be interrupted with 2-minute notice
- **Mitigation**: Karpenter automatically replaces interrupted nodes

### 2. Instance Flexibility
- **Categories**: c, m, r (multiple families)
- **Sizes**: 4-32 vCPUs (wide range)
- **Benefit**: Karpenter chooses cheapest available

### 3. Consolidation
- **Policy**: WhenEmpty after 30s
- **Benefit**: Removes unused nodes quickly
- **Savings**: Pay only for what you use

### 4. Right-Sizing
- **Method**: Karpenter selects smallest instance that fits
- **Benefit**: No over-provisioning
- **Example**: 1Gi pod → c5.large, not c5.4xlarge

### 5. Generation Constraint
- **Requirement**: Generation > 5
- **Benefit**: Modern instances have better price/performance
- **Examples**: c6i vs c5, m6i vs m5

---

## Security Features

### 1. Private Subnets
- Nodes launched in private subnets only
- No public IP addresses
- Internet access via NAT Gateway

### 2. Security Groups
- Uses cluster primary security group
- Managed by EKS
- Allows control-plane-to-node communication

### 3. IAM Roles
- Least privilege node role
- No hardcoded credentials
- IRSA for pod-level permissions

### 4. Encrypted Storage
- Ephemeral storage: gp3 with encryption
- Persistent volumes: Encrypted by default
- KMS key from cluster stage

### 5. Security Context
- No privilege escalation
- Non-root containers (best practice)
- Read-only root filesystem (optional)

---

## Testing and Verification

### After Deployment

```bash
# Verify NodeClass exists
kubectl get nodeclass

# Verify NodePool exists
kubectl get nodepool

# Check NodePool status
kubectl describe nodepool my-node-pool2

# Verify StorageClass
kubectl get storageclass
kubectl get storageclass auto-ebs-sc -o yaml

# Test Karpenter provisioning
kubectl scale deployment inflate --replicas=5

# Watch nodes being created
kubectl get nodes -w

# Check node labels
kubectl get nodes --show-labels

# Verify pods are scheduled
kubectl get pods -l app=inflate

# Check Karpenter logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter

# Test consolidation
kubectl scale deployment inflate --replicas=0
# Wait 30+ seconds
kubectl get nodes -w

# Test PVC creation
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF

kubectl get pvc
kubectl get pv
```

---

## Common Issues

### Issue: Nodes not provisioning
**Causes**:
- NodePool requirements too restrictive
- No available capacity (spot)
- IAM permissions missing
- Subnet/security group misconfigured

**Solutions**:
```bash
# Check Karpenter logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter

# Verify NodePool
kubectl describe nodepool my-node-pool2

# Check pending pods
kubectl get pods -A | grep Pending
kubectl describe pod <pending-pod>

# Verify IAM role
aws iam get-role --role-name <node-role-name>
```

### Issue: Nodes not consolidating
**Causes**:
- Pods with PVCs (can't move)
- Pods without disruption budgets
- Node not actually empty

**Solutions**:
```bash
# Check node utilization
kubectl top nodes

# Check pods on node
kubectl get pods -A --field-selector spec.nodeName=<node-name>

# Check Karpenter consolidation logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter | grep consolidation
```

### Issue: PVC not binding
**Causes**:
- EBS CSI driver not installed
- StorageClass not default
- Pod not scheduled yet (WaitForFirstConsumer)

**Solutions**:
```bash
# Check EBS CSI driver
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver

# Verify StorageClass
kubectl get storageclass

# Check PVC events
kubectl describe pvc <pvc-name>
```

### Issue: Spot instances interrupted frequently
**Causes**:
- High spot interruption rate in region
- Instance type with low spot availability

**Solutions**:
```bash
# Add more instance types to NodePool
# Use on-demand as fallback
# Check spot interruption rates:
# https://aws.amazon.com/ec2/spot/instance-advisor/
```

---

## Extending the Configuration

### Adding More Instance Types

```yaml
requirements:
  - key: "eks.amazonaws.com/instance-category"
    operator: In
    values: ["c", "m", "r", "t"]  # Add t (burstable)
  
  - key: "eks.amazonaws.com/instance-cpu"
    operator: In
    values: ["2", "4", "8", "16", "32"]  # Add 2 vCPU
```

### Using Graviton (ARM) Instances

```yaml
requirements:
  - key: "kubernetes.io/arch"
    operator: In
    values: ["amd64", "arm64"]  # Add arm64
  
  - key: "eks.amazonaws.com/instance-category"
    operator: In
    values: ["c", "m", "r", "t"]  # Graviton available in all
```

### On-Demand Only

```yaml
requirements:
  - key: "karpenter.sh/capacity-type"
    operator: In
    values: ["on-demand"]  # Remove spot
```

### Spot Only (Maximum Savings)

```yaml
requirements:
  - key: "karpenter.sh/capacity-type"
    operator: In
    values: ["spot"]  # Remove on-demand
```

### Multiple NodePools

Create separate NodePools for different workload types:

```yaml
# NodePool for batch jobs (spot only)
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: batch-pool
spec:
  template:
    spec:
      requirements:
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["spot"]
        - key: "workload-type"
          operator: In
          values: ["batch"]

---
# NodePool for critical services (on-demand only)
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: critical-pool
spec:
  template:
    spec:
      requirements:
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["on-demand"]
        - key: "workload-type"
          operator: In
          values: ["critical"]
```

---

## Best Practices

### DO:
✅ Use spot instances for fault-tolerant workloads  
✅ Set resource requests on all pods  
✅ Use disruption budgets for controlled updates  
✅ Enable consolidation to reduce costs  
✅ Use multiple instance types for flexibility  
✅ Set appropriate expiration times  
✅ Use WaitForFirstConsumer for PVCs  
✅ Monitor Karpenter logs regularly

### DON'T:
❌ Use spot for stateful workloads without backups  
❌ Set overly restrictive instance requirements  
❌ Forget to set resource limits  
❌ Disable consolidation in production  
❌ Use only one instance type  
❌ Set expiration too short (< 24h)  
❌ Use Immediate volume binding  
❌ Ignore Karpenter metrics

---

## Related Documentation

- **cluster Stage**: See `docs/README-cluster.md` for EKS cluster setup
- **net Stage**: See `docs/README-net.md` for network infrastructure
- **common-files**: See `docs/README-common-files.md` for shared configuration
- **addons Stage**: Next stage that installs cluster add-ons
- **Karpenter Documentation**: https://karpenter.sh/docs/
- **EKS Best Practices**: https://aws.github.io/aws-eks-best-practices/

---

## Summary

The nodepool stage configures Karpenter for automatic, efficient node provisioning with:
- Flexible instance selection (c, m, r families, 4-32 vCPUs)
- Cost optimization through spot instances and consolidation
- Automatic node lifecycle management (expiration, disruption budgets)
- Secure configuration (private subnets, encrypted storage)
- Default storage class for persistent volumes
- Test deployment to validate provisioning

This configuration enables the cluster to automatically scale nodes based on pod requirements while optimizing for cost and maintaining high availability.
