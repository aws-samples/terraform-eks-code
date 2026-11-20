#!/usr/bin/env bash
#
# Destroy all workshop stages in reverse build order.
#
# Usage:
#   ./destroy-everything.sh          # asks for confirmation
#   ./destroy-everything.sh --yes    # no prompt
#
# Run from anywhere: paths are resolved from this script's location.
# Stops at the first stage that fails, so tf-setup (which owns the state bucket and
# the only copy of its own state) is never destroyed while other stages still have resources.
# Never deletes .terraform.lock.hcl or terraform.tfstate files.
#
# The Kubernetes stages need the cluster API to be reachable (the IDE instance, or a
# public cluster endpoint). Output is shown and appended to .aws-staff/destroy.log.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG="$SCRIPT_DIR/destroy.log"

# Reverse of the build order
STAGES=(istio observ sampleapp addons nodepool cluster net tf-setup)
K8S_STAGES=" istio observ sampleapp addons nodepool "

export AWS_REGION="${AWS_REGION:-eu-west-1}"
export AWS_DEFAULT_REGION="$AWS_REGION"
export TF_IN_AUTOMATION=1

ASSUME_YES=0
[[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]] && ASSUME_YES=1

exec > >(tee -a "$LOG") 2>&1

log() { echo "[$(date '+%H:%M:%S')] $*"; }
die() { log "ERROR: $*"; log "stopping - later stages (including tf-setup) were NOT destroyed"; exit 1; }

ssm() { aws ssm get-parameter --name "$1" --query Parameter.Value --output text 2>/dev/null || true; }

# ------------------------------------------------------------------ pre-flight
for c in terraform aws kubectl jq; do
    command -v "$c" >/dev/null || die "'$c' not found on PATH"
done
ARN=$(aws sts get-caller-identity --query Arn --output text) || die "no working AWS credentials"
CLUSTER=$(ssm /workshop/tf-eks/cluster-name)
BUCKET=$(ssm /workshop/tf-eks/bucket-name)
EKS_VPC=$(ssm /workshop/tf-eks/eks-vpc)

log "AWS identity : $ARN"
log "region       : $AWS_REGION"
log "cluster      : ${CLUSTER:-<none>}"
log "state bucket : ${BUCKET:-<none>}"
log "stages       : ${STAGES[*]}"

if [[ $ASSUME_YES -ne 1 ]]; then
    read -r -p "This destroys ALL workshop resources above. Type 'destroy' to continue: " answer
    [[ "$answer" == "destroy" ]] || { log "aborted"; exit 1; }
fi

BUCKET_EXISTS=0
if [[ -n "$BUCKET" ]] && aws s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
    BUCKET_EXISTS=1
fi

CLUSTER_UP=0
if [[ -n "$CLUSTER" ]] && aws eks describe-cluster --name "$CLUSTER" >/dev/null 2>&1; then
    CLUSTER_UP=1
fi

# ------------------------------------------------------------------ helpers
check_cluster_reachable() {
    kubectl version --request-timeout=15s >/dev/null 2>&1 \
        || die "cluster API not reachable from here (private endpoint?) - run from the IDE instance or enable the public endpoint"
}

# Auto Mode creates the NLBs for the ui and istio-ingress Services outside Terraform and
# removes them asynchronously; their ENIs block subnet/VPC deletion in the net stage.
wait_for_k8s_load_balancers() {
    [[ -n "$EKS_VPC" ]] || return 0
    local n i
    for i in $(seq 1 40); do
        n=$(aws elbv2 describe-load-balancers \
            --query "length(LoadBalancers[?VpcId=='$EKS_VPC' && starts_with(LoadBalancerName,'k8s-')])" \
            --output text)
        [[ "$n" -eq 0 ]] && { log "no Auto Mode load balancers left in $EKS_VPC"; return 0; }
        log "waiting for $n Auto Mode load balancer(s) in $EKS_VPC to be deleted ($i/40)"
        sleep 15
    done
    die "Auto Mode load balancers still present in $EKS_VPC after 10 minutes"
}

# Auto Mode nodes are terminated by EKS when the cluster is deleted; wait so their
# ENIs are gone before the net stage deletes the subnets.
# Auto Mode nodes are EC2 *managed* instances, hidden from list calls by default:
# --include-managed-resources is needed to see them (older CLIs lack it, so fall back).
count_cluster_instances() {
    local filters=("Name=tag:eks:eks-cluster-name,Values=$CLUSTER"
                   "Name=instance-state-name,Values=pending,running,shutting-down,stopping,stopped")
    aws ec2 describe-instances --include-managed-resources --filters "${filters[@]}" \
        --query 'length(Reservations[].Instances[])' --output text 2>/dev/null \
    || aws ec2 describe-instances --filters "${filters[@]}" \
        --query 'length(Reservations[].Instances[])' --output text
}

wait_for_cluster_instances() {
    [[ -n "$CLUSTER" ]] || return 0
    local n i
    for i in $(seq 1 40); do
        n=$(count_cluster_instances)
        [[ "$n" -eq 0 ]] && { log "no cluster EC2 instances left"; return 0; }
        log "waiting for $n cluster instance(s) to terminate ($i/40)"
        sleep 15
    done
    die "cluster instances still running after 10 minutes"
}

# The Grafana API key expires after 5 days; the Grafana provider then can't delete the
# dashboards. Recreate the key first so the destroy can authenticate.
refresh_grafana_key() {
    if terraform state list 2>/dev/null | grep -qx 'aws_grafana_workspace_api_key.key'; then
        log "observ: recreating the Grafana API key so the dashboards can be deleted"
        terraform apply -input=false -no-color -auto-approve \
            -replace=aws_grafana_workspace_api_key.key \
            -target=aws_grafana_workspace_api_key.key \
            || die "observ: could not recreate the Grafana API key"
    fi
}

destroy_stage() {
    local s="$1"
    local dir="$ROOT/$s"
    log "==== $s ===="
    [[ -d "$dir" ]] || die "stage directory $dir not found"
    cd "$dir"

    if [[ "$s" != "tf-setup" && $BUCKET_EXISTS -ne 1 ]]; then
        log "$s: state bucket not found - nothing to destroy for this stage, skipping"
        return 0
    fi
    if [[ "$K8S_STAGES" == *" $s "* ]]; then
        if [[ $CLUSTER_UP -ne 1 ]]; then
            log "$s: cluster $CLUSTER not found - its in-cluster resources are already gone"
        else
            check_cluster_reachable
        fi
    fi

    # Remove the provider/module cache only; .terraform.lock.hcl is committed and must stay
    rm -rf .terraform tfplan
    terraform init -input=false -no-color >/tmp/tf-init-"$s".log 2>&1 \
        || { cat /tmp/tf-init-"$s".log; die "$s: terraform init failed"; }

    local count
    count=$(terraform state list 2>/dev/null | grep -cvE '(^|\.)data\.' || true)
    if [[ "$count" -eq 0 ]]; then
        log "$s: no managed resources in state, skipping"
        return 0
    fi
    log "$s: destroying $count resource(s)"

    [[ "$s" == "observ" ]] && refresh_grafana_key
    [[ "$s" == "cluster" ]] && wait_for_k8s_load_balancers

    if ! terraform destroy -input=false -no-color -auto-approve; then
        log "$s: destroy failed - retrying once in 30s"
        sleep 30
        terraform destroy -input=false -no-color -auto-approve || die "$s: terraform destroy failed twice"
    fi

    [[ "$s" == "cluster" ]] && wait_for_cluster_instances
    log "DESTROYED $s"
}

# ------------------------------------------------------------------ main
log "destroy started (~20 minutes)"
for s in "${STAGES[@]}"; do
    destroy_stage "$s"
done
log "all stages destroyed"
log "not removed (not managed by these stages): the IDE CloudFormation stack 'vscode' and the"
log "Name=eksworkshop-vpc tag on the default VPC"
