#!/usr/bin/env bash
#
# Shared helpers for the stage validation tests (test00-tf-setup.sh ... test70-istio.sh).
# Source it; do not run it. Everything here is read-only against AWS and the cluster:
# the cluster tests use a throwaway kubeconfig so ~/.kube/config is never modified.
#
# shellcheck disable=SC2034  # variables are used by the sourcing scripts

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$LIB_DIR/../.." && pwd)"
SETUP="$ROOT/tf-setup"

PASS=0; FAIL=0; WARN=0
pass() { echo "  PASS  $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL  $*"; FAIL=$((FAIL+1)); }
warn() { echo "  WARN  $*"; WARN=$((WARN+1)); }
info() { echo "  INFO  $*"; }
section() { echo; echo "== $*"; }
# check <description> <expected> <actual>
check() { if [[ "$2" == "$3" ]]; then pass "$1 ($3)"; else fail "$1: expected '$2', got '$3'"; fi; }
# check_true <description> <command...>   - pass when the command succeeds
check_true() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }

summary() {
    echo
    echo "== Summary: $PASS passed, $FAIL failed, $WARN warnings"
    [[ $FAIL -eq 0 ]]
    exit $?
}
# Stop early (counts as a failure) - used when a stage is clearly not applied
abort() { fail "$*"; summary; }

require() {
    local c
    for c in "$@"; do command -v "$c" >/dev/null || { echo "'$c' not found on PATH"; exit 1; }; done
}

# ------------------------------------------------------------------ AWS
# Region: AWS_REGION, else the region in the generated backend files, else eu-west-1
setup_aws() {
    require aws jq
    if [[ -n "${AWS_REGION:-}" ]]; then
        REGION="$AWS_REGION"
    elif [[ -f "$SETUP/generated/backend-net.tf" ]]; then
        REGION=$(sed -n 's/^ *region *= *"\(.*\)"/\1/p' "$SETUP/generated/backend-net.tf" | head -1)
    fi
    REGION="${REGION:-eu-west-1}"
    export AWS_REGION="$REGION" AWS_DEFAULT_REGION="$REGION" AWS_PAGER=""
    ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) \
        || { echo "  FAIL  no working AWS credentials"; exit 1; }
    info "account $ACCOUNT  region $REGION"
}

# ssm <short-name>  -> value of /workshop/tf-eks/<short-name> (empty if missing)
ssm() { aws ssm get-parameter --name "/workshop/tf-eks/$1" --query Parameter.Value --output text 2>/dev/null; }

# check_ssm <short-name> [expected-type]  - exists, has the workshop tag; prints nothing on stdout
# Sets SSM_VALUE to the value.
check_ssm() {
    local n="/workshop/tf-eks/$1" want="${2:-String}" j t tag
    SSM_VALUE=""
    if ! j=$(aws ssm get-parameter --name "$n" --output json 2>/dev/null); then
        fail "SSM $n missing"; return 1
    fi
    SSM_VALUE=$(echo "$j" | jq -r '.Parameter.Value'); t=$(echo "$j" | jq -r '.Parameter.Type')
    tag=$(aws ssm list-tags-for-resource --resource-type Parameter --resource-id "$n" \
          --query "TagList[?Key=='workshop'].Value | [0]" --output text 2>/dev/null)
    if [[ "$t" == "$want" && "$tag" == "tf-eks-workshop" ]]; then
        pass "SSM $n = $(echo "$SSM_VALUE" | cut -c1-80)"
    else
        fail "SSM $n: type=$t (want $want) tag workshop=$tag (want tf-eks-workshop)"
    fi
}

# Workshop values written by tf-setup (needed by every later stage)
load_setup_params() {
    TFID=$(ssm id); KEYID=$(ssm keyid); KEYARN=$(ssm keyarn)
    CLUSTER_PARAM=$(ssm cluster-name); EKSVER=$(ssm eks-version); BUCKET=$(ssm bucket-name)
    [[ -n "$TFID" && -n "$CLUSTER_PARAM" ]] \
        || abort "tf-setup SSM parameters missing in $REGION - run tf-setup first (or set AWS_REGION)"
    # The cluster stage writes the real cluster name; fall back to the requested one
    CLUSTER=$(ssm eks-cluster-name); CLUSTER="${CLUSTER:-$CLUSTER_PARAM}"
}

# Is <stage>'s state file in the state bucket? (cheap "was it applied" signal)
check_state_file() {
    local key="terraform/$1.tfstate" n
    if ! aws s3api head-object --bucket "$BUCKET" --key "$key" >/dev/null 2>&1; then
        fail "s3://$BUCKET/$key missing - stage $1 not applied"; return 1
    fi
    n=$(aws s3 cp "s3://$BUCKET/$key" - 2>/dev/null \
        | jq '[.resources[] | select(.mode=="managed") | .instances | length] | add // 0')
    if [[ "${n:-0}" -gt 0 ]]; then pass "state $key has $n managed resource instances"
    else fail "state $key has no managed resources - stage $1 not applied (or destroyed)"; return 1; fi
}

# ------------------------------------------------------------------ Kubernetes
# Use a private kubeconfig for the cluster so the user's kubeconfig is untouched
K8S_OK=0
k8s_connect() {
    require kubectl
    KUBECONFIG="$(mktemp -t tfeks-kubeconfig.XXXXXX)"; export KUBECONFIG
    trap 'rm -f "$KUBECONFIG"' EXIT
    if ! aws eks update-kubeconfig --name "$CLUSTER" --kubeconfig "$KUBECONFIG" >/dev/null 2>&1; then
        fail "could not build a kubeconfig for $CLUSTER"; return 1
    fi
    if kubectl version --request-timeout=15s >/dev/null 2>&1; then
        pass "cluster API reachable with kubectl"; K8S_OK=1
    else
        fail "cluster API not reachable (private endpoint - run from the IDE instance); Kubernetes checks skipped"
        return 1
    fi
}

check_ns() {
    if kubectl get ns "$1" >/dev/null 2>&1; then pass "namespace $1 exists"; else fail "namespace $1 missing"; return 1; fi
}

# check_workload <deployment|statefulset|daemonset> <ns> <name>  - exists and all replicas ready
check_workload() {
    local kind="$1" ns="$2" name="$3" j want have
    if ! j=$(kubectl get "$kind" -n "$ns" "$name" -o json 2>/dev/null); then
        fail "$kind $ns/$name missing"; return 1
    fi
    if [[ "$kind" == "daemonset" ]]; then
        want=$(echo "$j" | jq -r '.status.desiredNumberScheduled // 0'); have=$(echo "$j" | jq -r '.status.numberReady // 0')
    else
        want=$(echo "$j" | jq -r '.spec.replicas // 1'); have=$(echo "$j" | jq -r '.status.readyReplicas // 0')
    fi
    if [[ "$have" == "$want" ]]; then pass "$kind $ns/$name ready ($have/$want)"
    else fail "$kind $ns/$name: $have/$want ready"; return 1; fi
}

# check_all_pods <ns>  - every pod Running/Succeeded with all containers ready
check_all_pods() {
    local ns="$1" j total bad
    j=$(kubectl get pods -n "$ns" -o json 2>/dev/null) || { fail "cannot list pods in $ns"; return 1; }
    total=$(echo "$j" | jq '.items | length')
    bad=$(echo "$j" | jq -r '.items[] | select(
            (.status.phase != "Succeeded") and
            ((.status.phase != "Running") or ([.status.containerStatuses[]? | select(.ready | not)] | length > 0))
          ) | "\(.metadata.name)=\(.status.phase)"' | tr '\n' ' ')
    if [[ "$total" -eq 0 ]]; then fail "no pods in $ns"
    elif [[ -z "$bad" ]]; then pass "all $total pods in $ns running and ready"
    else fail "pods not ready in $ns: $bad"; fi
}

# check_helm_release <ns> <release>  - Helm v3 keeps release records in secrets labelled owner=helm
check_helm_release() {
    local st
    st=$(kubectl get secret -n "$1" -l "owner=helm,name=$2" \
         -o jsonpath='{range .items[*]}{.metadata.labels.version}{" "}{.metadata.labels.status}{"\n"}{end}' 2>/dev/null \
         | sort -n | tail -1 | awk '{print $2}')
    check "helm release $1/$2 status" "deployed" "${st:-missing}"
}

# check_irsa_sa <ns> <sa>  - service account has an IRSA role annotation and the role exists
check_irsa_sa() {
    local arn role
    arn=$(kubectl get sa -n "$1" "$2" -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}' 2>/dev/null)
    if [[ -z "$arn" ]]; then fail "service account $1/$2 has no eks.amazonaws.com/role-arn annotation"; return 1; fi
    role="${arn##*/}"
    if aws iam get-role --role-name "$role" >/dev/null 2>&1; then pass "SA $1/$2 -> IAM role $role exists"
    else fail "SA $1/$2 -> IAM role $role does not exist"; fi
}

# check_internal_nlb <ns> <service>  - LoadBalancer service has an internal, active NLB with healthy targets
# Sets LB_HOST.
check_internal_nlb() {
    local ns="$1" svc="$2" lb arn scheme state tg unhealthy i
    LB_HOST=""
    for i in 1 2 3 4 5 6; do
        LB_HOST=$(kubectl get svc -n "$ns" "$svc" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        [[ -n "$LB_HOST" ]] && break; sleep 5
    done
    if [[ -z "$LB_HOST" ]]; then fail "service $ns/$svc has no load balancer hostname"; return 1; fi
    pass "service $ns/$svc load balancer $LB_HOST"
    lb=$(aws elbv2 describe-load-balancers --output json 2>/dev/null \
         | jq -c --arg h "$LB_HOST" '.LoadBalancers[] | select(.DNSName==$h)')
    if [[ -z "$lb" ]]; then fail "no ELBv2 load balancer with DNS $LB_HOST"; return 1; fi
    arn=$(echo "$lb" | jq -r .LoadBalancerArn); scheme=$(echo "$lb" | jq -r .Scheme); state=$(echo "$lb" | jq -r .State.Code)
    check "$svc NLB type" "network" "$(echo "$lb" | jq -r .Type)"
    check "$svc NLB scheme (VPC only)" "internal" "$scheme"
    check "$svc NLB state" "active" "$state"
    unhealthy=""
    for tg in $(aws elbv2 describe-target-groups --load-balancer-arn "$arn" --query 'TargetGroups[].TargetGroupArn' --output text); do
        unhealthy+=$(aws elbv2 describe-target-health --target-group-arn "$tg" \
            --query "TargetHealthDescriptions[?TargetHealth.State!='healthy'].[Target.Id,TargetHealth.State]" --output text)
    done
    [[ -z "$unhealthy" ]] && pass "$svc NLB targets all healthy" || fail "$svc NLB unhealthy targets: $(echo "$unhealthy" | tr '\n\t' '  ')"
}
