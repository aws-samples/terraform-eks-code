#!/usr/bin/env bash
#
# Validate the addons stage:
#   - EKS add-ons amazon-cloudwatch-observability and metrics-server (aws_eks_addon)
#   - external-dns from eks-blueprints-addons: Helm release, IRSA role scoped to the net stage's
#     Route 53 zone, and no permission errors in its logs
#   - external-secrets is configured in main.tf but enable_external_secrets is not set, so it is
#     only reported if present
#
# Usage: ./test40-addons.sh    Needs: aws, jq, kubectl. Read-only.
#
set -uo pipefail
# shellcheck source=lib-test.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib-test.sh"

section "AWS identity and parameters"
setup_aws
load_setup_params
check_state_file addons
PHZ=$(ssm phz-id); PHZ="${PHZ##*/}"

# ------------------------------------------------------------------ EKS add-ons
section "EKS add-ons"
for a in amazon-cloudwatch-observability metrics-server; do
    A=$(aws eks describe-addon --cluster-name "$CLUSTER" --addon-name "$a" --output json 2>/dev/null | jq '.addon')
    if [[ -z "$A" || "$A" == "null" ]]; then fail "add-on $a not installed"; continue; fi
    check "add-on $a status" "ACTIVE" "$(echo "$A" | jq -r .status)"
    check "add-on $a health issues" "0" "$(echo "$A" | jq '.health.issues | length')"
    info "add-on $a version $(echo "$A" | jq -r .addonVersion)"
done

section "Kubernetes API"
k8s_connect || summary

section "CloudWatch observability (amazon-cloudwatch namespace)"
if check_ns amazon-cloudwatch; then
    check_workload deployment amazon-cloudwatch amazon-cloudwatch-observability-controller-manager
    for ds in $(kubectl get ds -n amazon-cloudwatch -o jsonpath='{.items[*].metadata.name}'); do
        check_workload daemonset amazon-cloudwatch "$ds"
    done
    LGN="/aws/containerinsights/$CLUSTER/performance"
    if [[ -n "$(aws logs describe-log-groups --log-group-name-prefix "$LGN" --query 'logGroups[0].logGroupName' --output text 2>/dev/null | grep -v None)" ]]; then
        pass "Container Insights log group $LGN exists"
    else
        warn "Container Insights log group $LGN not created yet (appears once agents send data)"
    fi
fi

section "metrics-server"
check_workload deployment kube-system metrics-server
check "APIService v1beta1.metrics.k8s.io Available" "True" \
    "$(kubectl get apiservice v1beta1.metrics.k8s.io -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)"
if [[ $(kubectl get nodes --no-headers 2>/dev/null | wc -l) -gt 0 ]]; then
    check_true "kubectl top nodes returns metrics" kubectl top nodes
else
    warn "no nodes - kubectl top skipped"
fi

section "external-dns"
if check_ns external-dns; then
    check_helm_release external-dns external-dns
    check_workload deployment external-dns external-dns
    check_irsa_sa external-dns external-dns
    ROLE=$(kubectl get sa -n external-dns external-dns -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}' 2>/dev/null); ROLE="${ROLE##*/}"
    FOUND=0
    for pa in $(aws iam list-attached-role-policies --role-name "$ROLE" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null); do
        v=$(aws iam get-policy --policy-arn "$pa" --query Policy.DefaultVersionId --output text)
        aws iam get-policy-version --policy-arn "$pa" --version-id "$v" --query PolicyVersion.Document --output json \
            | grep -q "hostedzone/$PHZ" && FOUND=1
    done
    [[ $FOUND -eq 1 ]] && pass "external-dns IAM policy is scoped to hosted zone $PHZ" \
        || fail "external-dns IAM policy does not reference hosted zone $PHZ"
    ARGS=$(kubectl get deploy -n external-dns external-dns -o jsonpath='{.spec.template.spec.containers[0].args}')
    [[ "$ARGS" == *"--policy=upsert-only"* ]] && pass "external-dns policy upsert-only" || fail "external-dns is not running with --policy=upsert-only"
    [[ "$ARGS" == *"--provider=aws"* ]] && pass "external-dns provider aws" || fail "external-dns provider is not aws"
    ERRS=$(kubectl logs -n external-dns deploy/external-dns --since=30m 2>/dev/null | grep -ciE 'AccessDenied|level=(error|fatal)')
    check "external-dns error lines in the last 30 minutes" "0" "$ERRS"
fi

section "external-secrets (configured, not enabled)"
if kubectl get ns external-secrets >/dev/null 2>&1; then
    check_workload deployment external-secrets external-secrets
else
    info "external-secrets not deployed (main.tf sets external_secrets = {...} but not enable_external_secrets = true)"
fi

summary
