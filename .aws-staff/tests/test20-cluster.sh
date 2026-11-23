#!/usr/bin/env bash
#
# Validate the cluster stage: EKS Auto Mode cluster (terraform-aws-modules/eks), private endpoint,
# control plane logging, secrets encryption with the eks/<name> KMS key, OIDC provider (IRSA),
# Auto Mode node role + access entry, extra security group rules and the SSM parameters it writes.
# kubectl checks: API reachable, Auto Mode CRDs / storage / CSI drivers, the caller has admin.
#
# Usage: ./test20-cluster.sh    Needs: aws, jq, kubectl (from a host that can reach the private endpoint). Read-only.
#
set -uo pipefail
# shellcheck source=lib-test.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib-test.sh"

LOG_TYPES='["api","audit","authenticator","controllerManager","scheduler"]'

section "AWS identity and tf-setup parameters"
setup_aws
load_setup_params
check_state_file cluster

# ------------------------------------------------------------------ SSM
section "SSM parameters written by cluster"
check_ssm eks-cluster-name;   check "eks-cluster-name = cluster-name" "$CLUSTER_PARAM" "$SSM_VALUE"
check_ssm oidc_provider_arn;  P_OIDC="$SSM_VALUE"
check_ssm cluster-sg;         P_SG="$SSM_VALUE"
check_ssm ca;                 P_CA="$SSM_VALUE"
check_ssm endpoint;           P_EP="$SSM_VALUE"
check_ssm eks-node-role-name; P_NODEROLE="$SSM_VALUE"

# ------------------------------------------------------------------ cluster
section "EKS cluster $CLUSTER"
C=$(aws eks describe-cluster --name "$CLUSTER" --output json 2>/dev/null | jq '.cluster')
[[ -n "$C" && "$C" != "null" ]] || abort "cluster $CLUSTER not found"
c() { echo "$C" | jq -r "$1"; }
check "status" "ACTIVE" "$(c .status)"
check "Kubernetes version = eks-version parameter" "$EKSVER" "$(c .version)"
check "public endpoint" "false" "$(c .resourcesVpcConfig.endpointPublicAccess)"
check "private endpoint" "true" "$(c .resourcesVpcConfig.endpointPrivateAccess)"
check "authentication mode" "API_AND_CONFIG_MAP" "$(c .accessConfig.authenticationMode)"
check "Auto Mode compute" "true" "$(c .computeConfig.enabled)"
check "Auto Mode block storage" "true" "$(c .storageConfig.blockStorage.enabled)"
check "Auto Mode load balancing" "true" "$(c .kubernetesNetworkConfig.elasticLoadBalancing.enabled)"
check "endpoint = SSM endpoint" "$P_EP" "$(c .endpoint)"
check "CA = SSM ca" "$P_CA" "$(c .certificateAuthority.data)"
check "cluster SG = SSM cluster-sg" "$P_SG" "$(c .resourcesVpcConfig.clusterSecurityGroupId)"
check "VPC = SSM eks-vpc" "$(ssm eks-vpc)" "$(c .resourcesVpcConfig.vpcId)"
SUBS=$(c '.resourcesVpcConfig.subnetIds[]' | sort | tr '\n' ' ')
WANT=$( (ssm private_subnets; ssm intra_subnets) | jq -r '.[]' | sort | tr '\n' ' ')
check "cluster subnets = private + intra subnets" "$WANT" "$SUBS"
check "enabled log types" "$(echo "$LOG_TYPES" | jq -c 'sort')" \
    "$(echo "$C" | jq -c '[.logging.clusterLogging[] | select(.enabled) | .types[]] | sort')"
LG="/aws/eks/$CLUSTER/cluster"
check "control plane log group $LG exists" "$LG" \
    "$(aws logs describe-log-groups --log-group-name-prefix "$LG" --query "logGroups[?logGroupName=='$LG'].logGroupName | [0]" --output text)"

section "Secrets encryption (KMS alias eks/$CLUSTER)"
ENC_KEY=$(c '.encryptionConfig[0].provider.keyArn')
check "encrypted resources" "secrets" "$(c '.encryptionConfig[0].resources | join(",")')"
ALIAS_KEY=$(aws kms describe-key --key-id "alias/eks/$CLUSTER" --query KeyMetadata.Arn --output text 2>/dev/null)
check "encryption key = alias/eks/$CLUSTER" "$ALIAS_KEY" "$ENC_KEY"
check "encryption key state" "Enabled" "$(aws kms describe-key --key-id "$ENC_KEY" --query KeyMetadata.KeyState --output text 2>/dev/null)"

section "OIDC provider (IRSA)"
ISSUER=$(c .identity.oidc.issuer)
check "oidc_provider_arn matches issuer" "arn:aws:iam::$ACCOUNT:oidc-provider/${ISSUER#https://}" "$P_OIDC"
if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$P_OIDC" --output json >/tmp/tfeks-oidc.json 2>/dev/null; then
    pass "IAM OIDC provider exists"
    jq -e '.ClientIDList | index("sts.amazonaws.com")' /tmp/tfeks-oidc.json >/dev/null \
        && pass "OIDC client id sts.amazonaws.com" || fail "OIDC provider lacks client id sts.amazonaws.com"
else
    fail "IAM OIDC provider $P_OIDC not found"
fi
rm -f /tmp/tfeks-oidc.json

section "Auto Mode node role and access entries"
NODE_ARN=$(c .computeConfig.nodeRoleArn)
if [[ "$NODE_ARN" == "null" || -z "$NODE_ARN" ]]; then
    # module only passes node_role_arn when node_pools are set; the role still exists
    NODE_ARN=$(aws iam get-role --role-name "$P_NODEROLE" --query Role.Arn --output text 2>/dev/null)
fi
check "node role name = SSM eks-node-role-name" "$P_NODEROLE" "${NODE_ARN##*/}"
POLS=$(aws iam list-attached-role-policies --role-name "$P_NODEROLE" --query 'AttachedPolicies[].PolicyName' --output text 2>/dev/null)
for p in AmazonEKSWorkerNodeMinimalPolicy AmazonEC2ContainerRegistryPullOnly CloudWatchAgentServerPolicy; do
    [[ "$(echo "$POLS" | tr '\t' '\n' | grep -cx "$p")" -eq 1 ]] && pass "node role has $p" || fail "node role missing $p"
done
CROLE=$(c .roleArn); CROLE="${CROLE##*/}"
CPOLS=$(aws iam list-attached-role-policies --role-name "$CROLE" --query 'AttachedPolicies[].PolicyName' --output text 2>/dev/null)
for p in AmazonEKSClusterPolicy AmazonEKSComputePolicy AmazonEKSLoadBalancingPolicy AmazonEKSNetworkingPolicy; do
    [[ "$(echo "$CPOLS" | tr '\t' '\n' | grep -cx "$p")" -eq 1 ]] && pass "cluster role $CROLE has $p" || fail "cluster role $CROLE missing $p"
done
echo "$CPOLS" | tr '\t' '\n' | grep -q '^AmazonEKSBlockStoragePolicy' && pass "cluster role has AmazonEKSBlockStoragePolicy" \
    || fail "cluster role missing AmazonEKSBlockStoragePolicy(V2)"
AE=$(aws eks describe-access-entry --cluster-name "$CLUSTER" --principal-arn "$NODE_ARN" --output json 2>/dev/null | jq '.accessEntry')
check "node role access entry type" "EC2" "$(echo "$AE" | jq -r '.type // "missing"')"
check "node role access policy" "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy" \
    "$(aws eks list-associated-access-policies --cluster-name "$CLUSTER" --principal-arn "$NODE_ARN" --query 'associatedAccessPolicies[0].policyArn' --output text 2>/dev/null)"
ME=$(aws sts get-caller-identity --query Arn --output text)
ENTRIES=$(aws eks list-access-entries --cluster-name "$CLUSTER" --query accessEntries --output text | tr '\t' '\n')
CREATOR=$(echo "$ENTRIES" | grep -v "$NODE_ARN" | grep -v 'AWSServiceRole' | tr '\n' ' ')
[[ -n "$CREATOR" ]] && pass "cluster creator access entry present ($CREATOR)" || fail "no access entry apart from the node role"
info "caller is $ME"

section "Cluster primary security group rules"
DEFCIDR=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=eksworkshop-vpc --query 'Vpcs[0].CidrBlock' --output text)
SG=$(aws ec2 describe-security-groups --group-ids "$P_SG" --output json | jq '.SecurityGroups[0]')
echo "$SG" | jq -e --arg c "$DEFCIDR" '.IpPermissions[] | select(.IpProtocol=="tcp" and .FromPort==443) | .IpRanges[] | select(.CidrIp==$c)' >/dev/null \
    && pass "cluster SG allows tcp/443 from IDE VPC $DEFCIDR" || fail "cluster SG missing tcp/443 from $DEFCIDR"
echo "$SG" | jq -e --arg c "$DEFCIDR" '.IpPermissionsEgress[] | select(.IpProtocol=="-1") | .IpRanges[] | select(.CidrIp==$c)' >/dev/null \
    && pass "cluster SG allows all egress to $DEFCIDR" || fail "cluster SG missing egress to $DEFCIDR"

# ------------------------------------------------------------------ kubectl
section "Kubernetes API"
if k8s_connect; then
    SV=$(kubectl version -o json 2>/dev/null | jq -r '.serverVersion | "\(.major).\(.minor)"' | tr -d '+')
    check "API server version" "$EKSVER" "$SV"
    check "caller is cluster admin (can-i '*' '*')" "yes" "$(kubectl auth can-i '*' '*' --all-namespaces 2>/dev/null)"
    CRDS=$(kubectl get crds -o name 2>/dev/null)
    for crd in nodeclasses.eks.amazonaws.com nodepools.karpenter.sh nodeclaims.karpenter.sh \
               ingressclassparams.eks.amazonaws.com targetgroupbindings.eks.amazonaws.com \
               cninodes.eks.amazonaws.com nodediagnostics.eks.amazonaws.com; do
        [[ "$CRDS" == *"customresourcedefinition.apiextensions.k8s.io/$crd"* ]] && pass "CRD $crd" || fail "CRD $crd missing"
    done
    kubectl get csidriver ebs.csi.eks.amazonaws.com >/dev/null 2>&1 && pass "Auto Mode EBS CSI driver registered" \
        || fail "CSI driver ebs.csi.eks.amazonaws.com missing"
    kubectl get nodeclass default >/dev/null 2>&1 && pass "Auto Mode default NodeClass exists" \
        || info "no 'default' NodeClass (expected: no built-in node pools are enabled)"
    check_true "kube-system namespace readable" kubectl get pods -n kube-system
fi

summary
