# Inflate Test Deployment
# Test deployment to validate Karpenter node provisioning
# Starts with 0 replicas - scale up to trigger node creation

resource "kubectl_manifest" "inflate" {
# Depends on NodePool being created first
depends_on=[kubectl_manifest.karpenter_node_pool2]

yaml_body = <<-YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  # Initial replicas: 0 (no pods created initially)
  # Scale up to test Karpenter: kubectl scale deployment inflate --replicas=5
  replicas: 0
  
  selector:
    matchLabels:
      app: inflate
  
  template:
    metadata:
      labels:
        app: inflate
    
    spec:
      # Immediate termination for testing
      # Production: Use 30+ seconds for graceful shutdown
      terminationGracePeriodSeconds: 0
      
      containers:
        - name: inflate
          # Minimal pause container from EKS Distro
          # Very small image (~1MB), does nothing but hold resources
          image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
          
          # Resource requests trigger node provisioning
          # Each pod requests 1Gi memory
          # Example: 5 replicas = 5Gi memory needed
          resources:
            requests:
              memory: 1Gi
          
          # Security best practice
          # Prevents privilege escalation attacks
          securityContext:
            allowPrivilegeEscalation: false
YAML
}

# Testing workflow:
# 1. Scale up: kubectl scale deployment inflate --replicas=5
# 2. Watch nodes: kubectl get nodes -w
# 3. Watch pods: kubectl get pods -l app=inflate -w
# 4. Scale down: kubectl scale deployment inflate --replicas=0
# 5. Watch consolidation: kubectl get nodes -w (nodes removed after 30s)