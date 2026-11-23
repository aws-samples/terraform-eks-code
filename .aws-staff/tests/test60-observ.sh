#!/usr/bin/env bash
#
# Validate the observ stage:
#   - Amazon Managed Grafana workspace "keycloak-blog" (SAML, customer-managed role grafana-assume
#     with Prometheus / CloudWatch / X-Ray read policies)
#   - observability-accelerator eks-monitoring module, collector_profile self-managed-amp:
#     AMP workspace "eks-monitoring" + alerting / recording rule groups, IRSA role
#     <cluster>-otel-collector, Helm releases otel-collector, kube-state-metrics,
#     prometheus-node-exporter and their workloads
#
# Usage: ./test60-observ.sh    Needs: aws, jq, kubectl. Read-only.
#
set -uo pipefail
# shellcheck source=lib-test.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib-test.sh"

section "AWS identity and parameters"
setup_aws
load_setup_params
check_state_file observ

# ------------------------------------------------------------------ Grafana
section "Amazon Managed Grafana"
GW=$(aws grafana list-workspaces --output json 2>/dev/null | jq -c '[.workspaces[] | select(.name=="keycloak-blog")] | .[0]')
if [[ -z "$GW" || "$GW" == "null" ]]; then fail "Grafana workspace keycloak-blog not found"; else
    GID=$(echo "$GW" | jq -r .id)
    G=$(aws grafana describe-workspace --workspace-id "$GID" --output json | jq '.workspace')
    check "workspace $GID status" "ACTIVE" "$(echo "$G" | jq -r .status)"
    check "authentication" "SAML" "$(echo "$G" | jq -r '.authentication.providers | join(",")')"
    check "permission type" "CUSTOMER_MANAGED" "$(echo "$G" | jq -r .permissionType)"
    check "account access" "CURRENT_ACCOUNT" "$(echo "$G" | jq -r .accountAccessType)"
    check "workspace role" "grafana-assume" "$(echo "$G" | jq -r '.workspaceRoleArn' | awk -F/ '{print $NF}')"
    info "endpoint https://$(echo "$G" | jq -r .endpoint)"
fi
POLS=$(aws iam list-attached-role-policies --role-name grafana-assume --query 'AttachedPolicies[].PolicyName' --output text 2>/dev/null | tr '\t' '\n')
for p in AmazonPrometheusQueryAccess AmazonGrafanaCloudWatchAccess AWSXrayReadOnlyAccess; do
    echo "$POLS" | grep -qx "$p" && pass "grafana-assume has $p" || fail "grafana-assume missing $p"
done
aws iam get-role --role-name grafana-assume --query 'Role.AssumeRolePolicyDocument' --output json 2>/dev/null \
    | grep -q 'grafana.amazonaws.com' && pass "grafana-assume trusts grafana.amazonaws.com" || fail "grafana-assume trust policy wrong"

# ------------------------------------------------------------------ AMP
section "Amazon Managed Service for Prometheus"
AMP=$(aws amp list-workspaces --alias eks-monitoring --output json 2>/dev/null | jq -c '.workspaces[0]')
if [[ -z "$AMP" || "$AMP" == "null" ]]; then fail "AMP workspace alias eks-monitoring not found"; else
    AID=$(echo "$AMP" | jq -r .workspaceId)
    check "AMP workspace $AID status" "ACTIVE" "$(echo "$AMP" | jq -r .status.statusCode)"
    RG=$(aws amp list-rule-groups-namespaces --workspace-id "$AID" --output json | jq -r '.ruleGroupsNamespaces[] | "\(.name)=\(.status.statusCode)"' | sort | tr '\n' ' ')
    check "rule group namespaces" "accelerator-v2-alerting-rules=ACTIVE accelerator-v2-recording-rules=ACTIVE " "$RG"
fi
ROLE="${CLUSTER}-otel-collector"
aws iam get-role --role-name "$ROLE" >/dev/null 2>&1 && pass "IAM role $ROLE exists" || fail "IAM role $ROLE missing"
RPOLS=$(aws iam list-attached-role-policies --role-name "$ROLE" --query 'AttachedPolicies[].PolicyName' --output text 2>/dev/null | tr '\t' '\n')
echo "$RPOLS" | grep -qi 'ManagedServicePrometheus' && pass "$ROLE has the AMP remote-write policy" || fail "$ROLE missing the AMP policy"
echo "$RPOLS" | grep -qx 'AWSXrayWriteOnlyAccess' && pass "$ROLE has AWSXrayWriteOnlyAccess (enable_tracing)" || fail "$ROLE missing AWSXrayWriteOnlyAccess"

# ------------------------------------------------------------------ Kubernetes
section "Kubernetes API"
k8s_connect || summary

section "Collectors"
check_helm_release otel-collector otel-collector
check_helm_release kube-system kube-state-metrics
check_helm_release prometheus-node-exporter prometheus-node-exporter
check_all_pods otel-collector
check_irsa_sa otel-collector otel-collector
check_workload deployment kube-system kube-state-metrics
NE=$(kubectl get ds -n prometheus-node-exporter -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
[[ -n "$NE" ]] && check_workload daemonset prometheus-node-exporter "$NE" || fail "node-exporter daemonset missing"
ERRS=$(kubectl logs -n otel-collector -l app.kubernetes.io/name=opentelemetry-collector --since=15m --tail=500 2>/dev/null \
       | grep -ciE '"error"|level=error|\berror\b.*(remote ?write|export|403|401)')
check "otel-collector error lines in the last 15 minutes" "0" "$ERRS"

summary
