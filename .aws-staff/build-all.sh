#!/usr/bin/env bash
#
# Build the workshop stages in order.
#
# Usage:
#   ./build-all.sh                 # all stages
#   ./build-all.sh net cluster     # only the named stages, in the order given
#
# Run from anywhere: paths are resolved from this script's location.
# Needs: terraform, aws, kubectl, jq; AWS credentials (AWS_PROFILE / default profile).
# The Kubernetes stages need the cluster API to be reachable (the IDE instance, or a
# public cluster endpoint).
#
# Output is shown and appended to .aws-staff/build.log.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG="$SCRIPT_DIR/build.log"

ALL_STAGES=(tf-setup net cluster nodepool addons sampleapp observ istio)
K8S_STAGES=" nodepool addons sampleapp observ istio "

export AWS_REGION="${AWS_REGION:-eu-west-1}"
export AWS_DEFAULT_REGION="$AWS_REGION"
export TF_IN_AUTOMATION=1

exec > >(tee -a "$LOG") 2>&1

log() { echo "[$(date '+%H:%M:%S')] $*"; }
die() { log "ERROR: $*"; exit 1; }

# ------------------------------------------------------------------ arguments
if [[ $# -gt 0 ]]; then
    STAGES=("$@")
    for s in "${STAGES[@]}"; do
        [[ " ${ALL_STAGES[*]} " == *" $s "* ]] || die "unknown stage '$s' (valid: ${ALL_STAGES[*]})"
    done
else
    STAGES=("${ALL_STAGES[@]}")
fi

# ------------------------------------------------------------------ pre-flight
preflight() {
    for c in terraform aws kubectl jq; do
        command -v "$c" >/dev/null || die "'$c' not found on PATH"
    done
    local arn
    arn=$(aws sts get-caller-identity --query Arn --output text) || die "no working AWS credentials"
    log "AWS identity: $arn  region: $AWS_REGION"

    # net looks up the IDE environment (the vscode CloudFormation stack) by tag
    if [[ " ${STAGES[*]} " == *" net "* ]]; then
        local vpc inst
        vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=eksworkshop-vpc \
              --query 'length(Vpcs)' --output text)
        inst=$(aws ec2 describe-instances \
               --filters Name=tag:Name,Values=eksworkshop-kiroide Name=instance-state-name,Values=running \
               --query 'length(Reservations)' --output text)
        [[ "$vpc" -ge 1 ]]  || die "no VPC tagged Name=eksworkshop-vpc (the IDE/default VPC) - deploy the IDE stack first"
        [[ "$inst" -ge 1 ]] || die "no running instance tagged Name=eksworkshop-kiroide - deploy/start the IDE stack first"
    fi
}

# The Kubernetes stages talk to the cluster API through kubectl / providers
check_cluster_reachable() {
    kubectl version --request-timeout=15s >/dev/null 2>&1 \
        || die "cluster API not reachable from here (private endpoint?) - run from the IDE instance or enable the public endpoint"
}

# ------------------------------------------------------------------ one stage
plan_and_apply() {
    # returns 0 when the stage has no changes left
    local rc=0
    terraform plan -input=false -no-color -detailed-exitcode -out=tfplan || rc=$?
    case $rc in
        0) log "$1: no changes"; return 0 ;;
        2) terraform apply -input=false -no-color tfplan ;;
        *) return 1 ;;
    esac
}

build_stage() {
    local s="$1"
    local dir="$ROOT/$s"
    [[ -d "$dir" ]] || die "stage directory $dir not found"
    log "==== $s ===="
    cd "$dir"

    if [[ "$K8S_STAGES" == *" $s "* ]]; then
        check_cluster_reachable
    fi

    # Remove the provider/module cache only; .terraform.lock.hcl is committed and must stay
    rm -rf .terraform tfplan
    terraform init -input=false -no-color >/tmp/tf-init-"$s".log 2>&1 \
        || { cat /tmp/tf-init-"$s".log; die "$s: terraform init failed"; }

    if ! plan_and_apply "$s"; then
        # One retry covers eventual-consistency failures on first create
        # (e.g. IAM propagation, EKS access entries)
        log "$s: apply failed - retrying once in 30s"
        sleep 30
        plan_and_apply "$s" || die "$s: terraform apply failed twice"
    fi
    rm -f tfplan

    local n
    n=$(terraform state list | grep -cvE '(^|\.)data\.' || true)
    log "PASSED $s ($n managed resources in state)"
}

# ------------------------------------------------------------------ post-build checks
post_checks() {
    log "==== post-build checks ===="
    check_cluster_reachable
    local fail=0

    if kubectl get nodes --no-headers | awk '$2!="Ready"{bad=1} END{exit bad}'; then
        log "nodes: all Ready"
    else
        log "nodes: some not Ready"; kubectl get nodes; fail=1
    fi

    if kubectl wait deploy --all -A --for=condition=Available --timeout=300s >/dev/null; then
        log "deployments: all Available"
    else
        log "deployments: some not Available"; fail=1
    fi

    local bad
    bad=$(kubectl get pods -A --no-headers --field-selector=status.phase!=Running,status.phase!=Succeeded | wc -l | tr -d ' ')
    if [[ "$bad" -eq 0 ]]; then
        log "pods: all Running/Completed ($(kubectl get pods -A --no-headers | wc -l | tr -d ' ') total)"
    else
        log "pods: $bad not Running/Completed"
        kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
        fail=1
    fi

    # Internal load balancers (reachable from the VPC / IDE instance only)
    local ui gw
    ui=$(kubectl get svc -n sampleapp ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
    gw=$(kubectl get svc -n istio-ingress istio-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
    [[ -n "$ui" ]] && log "sampleapp UI : http://$ui/"
    [[ -n "$gw" ]] && log "bookinfo     : http://$gw/productpage"

    [[ $fail -eq 0 ]] || die "post-build checks failed"
    log "post-build checks PASSED"
}

# ------------------------------------------------------------------ main
log "build started: ${STAGES[*]}  (full build ~40 minutes)"
preflight
for s in "${STAGES[@]}"; do
    build_stage "$s"
done
# Only check the workloads when the build ran up to the last stage
if [[ "${STAGES[${#STAGES[@]}-1]}" == "istio" ]]; then   # (no negative index: macOS bash 3.2)
    post_checks
fi
log "build finished"
