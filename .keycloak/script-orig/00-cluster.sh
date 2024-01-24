export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=$(aws configure get region)
export CLUSTER_NAME=mgmt-workshop
#export HOSTED_ZONE=<your-public-domain>  # dns name awsandy.people.aws.dev
export HOSTED_ZONE=$ACCOUNT_ID.awsandy.people.aws.dev
export CLUSTER_VERSION=1.27
echo $ACCOUNT_ID
echo $AWS_REGION
echo $CLUSTER_NAME
echo $HOSTED_ZONE
echo $CLUSTER_VERSION

cat << EOF > keycloak_blog_cluster.yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: $CLUSTER_NAME
  region: eu-west-1
  version: "$CLUSTER_VERSION"
addons:
  - name: vpc-cni
iam:
  withOIDC: true
  serviceAccounts:
    - metadata:
        name: aws-load-balancer-controller
        namespace: aws-lb
      roleName: keycloak-blog-aws-lb-controller
      roleOnly: true
      wellKnownPolicies:
        awsLoadBalancerController: true
    - metadata:
        name: external-dns
        namespace: external-dns
      roleName: keycloak-blog-external-dns
      roleOnly: true
      wellKnownPolicies:
        externalDNS: true
managedNodeGroups:
  - name: main
    iam:
      attachPolicyARNs:
        - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
        - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
    instanceType: t3.large
    privateNetworking: true
EOF

eksctl create cluster -f keycloak_blog_cluster.yaml