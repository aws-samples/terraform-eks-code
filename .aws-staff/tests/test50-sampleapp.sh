#!/usr/bin/env bash
#
# Validate the sampleapp stage (retail store sample app in namespace sampleapp):
# every Deployment / StatefulSet / Service / ConfigMap / Secret / ServiceAccount the stage
# defines exists and is ready, the ui LoadBalancer is an internal, healthy NLB, and the UI
# answers (through the API server service proxy, and directly when run inside the VPC).
#
# Usage: ./test50-sampleapp.sh    Needs: aws, jq, kubectl; curl optional. Read-only.
#
set -uo pipefail
# shellcheck source=lib-test.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib-test.sh"

NS=sampleapp
DEPLOYMENTS="assets carts carts-dynamodb catalog checkout checkout-redis orders ui"
STATEFULSETS="catalog-mysql orders-postgresql orders-rabbitmq"
SERVICES="assets carts carts-dynamodb catalog catalog-mysql checkout checkout-redis orders orders-postgresql orders-rabbitmq ui"
CONFIGMAPS="assets carts catalog checkout orders ui"
SECRETS="catalog-db orders-db orders-rabbitmq"
SAS="assets carts catalog checkout orders ui"

section "AWS identity and parameters"
setup_aws
load_setup_params
check_state_file sampleapp

section "Kubernetes API"
k8s_connect || summary
check_ns "$NS" || summary

section "Workloads"
for d in $DEPLOYMENTS; do check_workload deployment "$NS" "$d"; done
for s in $STATEFULSETS; do check_workload statefulset "$NS" "$s"; done
check_all_pods "$NS"
RESTARTS=$(kubectl get pods -n "$NS" -o json | jq '[.items[].status.containerStatuses[]?.restartCount] | add // 0')
[[ "$RESTARTS" -lt 10 ]] && pass "container restarts in $NS: $RESTARTS" || warn "container restarts in $NS: $RESTARTS"

section "Config objects"
have() { kubectl get "$1" -n "$NS" "$2" >/dev/null 2>&1 && pass "$1 $2" || fail "$1 $2 missing"; }
for x in $SERVICES;   do have service "$x"; done
for x in $CONFIGMAPS; do have configmap "$x"; done
for x in $SECRETS;    do have secret "$x"; done
for x in $SAS;        do have serviceaccount "$x"; done
# Each ClusterIP service must have ready endpoints
for x in $SERVICES; do
    n=$(kubectl get endpointslices -n "$NS" -l "kubernetes.io/service-name=$x" -o json 2>/dev/null \
        | jq '[.items[].endpoints[]? | select(.conditions.ready)] | length')
    [[ "${n:-0}" -gt 0 ]] && pass "service $x has $n ready endpoint(s)" || fail "service $x has no ready endpoints"
done

section "UI load balancer"
check "ui service type" "LoadBalancer" "$(kubectl get svc -n "$NS" ui -o jsonpath='{.spec.type}')"
check "ui scheme annotation" "internal" \
    "$(kubectl get svc -n "$NS" ui -o jsonpath='{.metadata.annotations.service\.beta\.kubernetes\.io/aws-load-balancer-scheme}')"
check_internal_nlb "$NS" ui

section "UI responds"
BODY=$(kubectl get --raw "/api/v1/namespaces/$NS/services/ui:http/proxy/" 2>/dev/null)
if [[ "$BODY" == *"<html"* || "$BODY" == *"<!DOCTYPE"* || "$BODY" == *"<!doctype"* ]]; then
    pass "UI home page served (via API server proxy)"
else
    warn "UI home page not returned through the API server proxy"
fi
if command -v curl >/dev/null && [[ -n "${LB_HOST:-}" ]]; then
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://$LB_HOST/" || true)
    if [[ "$code" == "200" ]]; then pass "http://$LB_HOST/ returns 200"
    else warn "http://$LB_HOST/ returned '$code' (internal NLB - only reachable from the VPC / IDE instance)"; fi
fi

summary
