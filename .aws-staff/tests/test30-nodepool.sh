#!/usr/bin/env bash
#
# Validate the nodepool stage (all Kubernetes objects, applied with the kubectl provider):
#   NodeClass mynodeclass, NodePool my-node-pool2, default StorageClass auto-ebs-sc and the
#   inflate deployment (0 replicas). Also checks that Auto Mode nodes launched from the pool
#   are Ready and use the subnets / security group the NodeClass selects.
#
# Usage: ./test30-nodepool.sh    Needs: aws, jq, kubectl. Read-only.
#
set -uo pipefail
# shellcheck source=lib-test.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib-test.sh"

section "AWS identity and parameters"
setup_aws
load_setup_params
check_state_file nodepool
NODE_ROLE=$(ssm eks-node-role-name); CLUSTER_SG=$(ssm cluster-sg)
PRIV=$(ssm private_subnets | jq -r '.[]' | sort | tr '\n' ' ')

section "Kubernetes API"
k8s_connect || summary

# ------------------------------------------------------------------ NodeClass
section "NodeClass mynodeclass"
NC=$(kubectl get nodeclass.eks.amazonaws.com mynodeclass -o json 2>/dev/null)
if [[ -z "$NC" ]]; then fail "NodeClass mynodeclass missing"; else
    check "Ready condition" "True" "$(echo "$NC" | jq -r '.status.conditions[]? | select(.type=="Ready") | .status')"
    check "role = SSM eks-node-role-name" "$NODE_ROLE" "$(echo "$NC" | jq -r .spec.role)"
    check "security group selector = SSM cluster-sg" "$CLUSTER_SG" "$(echo "$NC" | jq -r '.spec.securityGroupSelectorTerms[0].id')"
    check "resolved security groups" "$CLUSTER_SG" "$(echo "$NC" | jq -r '[.status.securityGroups[]?.id] | join(",")')"
    check "resolved subnets = private subnets" "$PRIV" "$(echo "$NC" | jq -r '.status.subnets[]?.id' | sort | tr '\n' ' ')"
    check "ephemeral storage size" "80Gi" "$(echo "$NC" | jq -r .spec.ephemeralStorage.size)"
    check "snatPolicy" "Random" "$(echo "$NC" | jq -r .spec.snatPolicy)"
fi

# ------------------------------------------------------------------ NodePool
section "NodePool my-node-pool2"
NP=$(kubectl get nodepool.karpenter.sh my-node-pool2 -o json 2>/dev/null)
if [[ -z "$NP" ]]; then fail "NodePool my-node-pool2 missing"; else
    check "Ready condition" "True" "$(echo "$NP" | jq -r '.status.conditions[]? | select(.type=="Ready") | .status')"
    check "nodeClassRef" "eks.amazonaws.com/NodeClass/mynodeclass" \
        "$(echo "$NP" | jq -r '.spec.template.spec.nodeClassRef | "\(.group)/\(.kind)/\(.name)"')"
    check "consolidation policy" "WhenEmpty" "$(echo "$NP" | jq -r .spec.disruption.consolidationPolicy)"
    check "cpu limit" "1000" "$(echo "$NP" | jq -r .spec.limits.cpu)"
    ZONES=$(aws ec2 describe-availability-zones --filters Name=opt-in-status,Values=opt-in-not-required \
            --query 'AvailabilityZones[].ZoneName' --output text | tr '\t' '\n' | sort | tr '\n' ' ')
    check "zone requirement = region AZs" "$ZONES" \
        "$(echo "$NP" | jq -r '.spec.template.spec.requirements[] | select(.key=="topology.kubernetes.io/zone") | .values[]' | sort | tr '\n' ' ')"
fi

# ------------------------------------------------------------------ StorageClass
section "StorageClass auto-ebs-sc"
SC=$(kubectl get storageclass auto-ebs-sc -o json 2>/dev/null)
if [[ -z "$SC" ]]; then fail "StorageClass auto-ebs-sc missing"; else
    check "provisioner" "ebs.csi.eks.amazonaws.com" "$(echo "$SC" | jq -r .provisioner)"
    check "default class" "true" "$(echo "$SC" | jq -r '.metadata.annotations["storageclass.kubernetes.io/is-default-class"]')"
    check "volumeBindingMode" "WaitForFirstConsumer" "$(echo "$SC" | jq -r .volumeBindingMode)"
    check "type/encrypted" "gp3/true" "$(echo "$SC" | jq -r '"\(.parameters.type)/\(.parameters.encrypted)"')"
    DEFAULTS=$(kubectl get storageclass -o json | jq -r '[.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"]=="true")] | length')
    check "exactly one default StorageClass" "1" "$DEFAULTS"
fi

# ------------------------------------------------------------------ inflate
section "inflate deployment"
INF=$(kubectl get deploy -n default inflate -o json 2>/dev/null)
if [[ -z "$INF" ]]; then fail "deployment default/inflate missing"; else
    pass "deployment default/inflate exists"
    info "inflate replicas: $(echo "$INF" | jq -r .spec.replicas) (Terraform sets 0; scale it up to test Auto Mode scaling)"
fi

# ------------------------------------------------------------------ nodes
section "Nodes from my-node-pool2"
NODES=$(kubectl get nodes -l karpenter.sh/nodepool=my-node-pool2 -o json 2>/dev/null)
N=$(echo "$NODES" | jq '.items | length')
if [[ "$N" -eq 0 ]]; then
    warn "no nodes from my-node-pool2 yet (Auto Mode only launches nodes when pods need them)"
else
    NR=$(echo "$NODES" | jq '[.items[] | select(.status.conditions[] | select(.type=="Ready" and .status=="True"))] | length')
    check "nodes Ready" "$N" "$NR"
    check "node arch" "amd64" "$(echo "$NODES" | jq -r '[.items[].metadata.labels["kubernetes.io/arch"]] | unique | join(",")')"
    check "nodes carry billing-team=my-team" "$N" "$(echo "$NODES" | jq '[.items[] | select(.metadata.labels["billing-team"]=="my-team")] | length')"
    BADCAT=$(echo "$NODES" | jq -r '.items[].metadata.labels["eks.amazonaws.com/instance-category"]' | grep -cv '^[cmr]$')
    check "nodes outside instance categories c/m/r" "0" "$BADCAT"
    for id in $(echo "$NODES" | jq -r '.items[].spec.providerID' | awk -F/ '{print $NF}'); do
        sn=$(aws ec2 describe-instances --instance-ids "$id" --query 'Reservations[0].Instances[0].SubnetId' --output text 2>/dev/null)
        [[ " $PRIV " == *" $sn "* ]] && pass "instance $id in private subnet $sn" || fail "instance $id in subnet $sn (not a private subnet)"
    done
fi
NOTREADY=$(kubectl get nodes --no-headers 2>/dev/null | awk '$2!="Ready"' | wc -l | tr -d ' ')
check "nodes not Ready (all pools)" "0" "$NOTREADY"

summary
