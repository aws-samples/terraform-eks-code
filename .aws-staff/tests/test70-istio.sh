#!/usr/bin/env bash
#
# Validate the istio stage:
#   - Helm releases istio-base, istiod (istio-system) and istio-ingress (istio-ingress), chart 1.30.8
#   - istio-ingress Service: internal NLB with ports 15021/80/443, healthy targets
#   - Bookinfo in namespace sample: sidecar injection, 6 deployments with istio-proxy, 4 services,
#     Gateway bookinfo-gateway and VirtualService bookinfo
#   - End to end: productpage answers inside the mesh and through the ingress gateway
#
# Usage: ./test70-istio.sh    Needs: aws, jq, kubectl; istioctl and curl optional. Read-only
#        (uses kubectl exec to run curl inside an existing ratings pod).
#
set -uo pipefail
# shellcheck source=lib-test.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib-test.sh"

ISTIO_VERSION="1.30.8"
BOOK_DEPLOYMENTS="details-v1 productpage-v1 ratings-v1 reviews-v1 reviews-v2 reviews-v3"
BOOK_SERVICES="details productpage ratings reviews"

section "AWS identity and parameters"
setup_aws
load_setup_params
check_state_file istio

section "Kubernetes API"
k8s_connect || summary

# ------------------------------------------------------------------ control plane
section "Istio control plane"
check_ns istio-system
check_ns istio-ingress
check_helm_release istio-system istio-base
check_helm_release istio-system istiod
check_helm_release istio-ingress istio-ingress
check_workload deployment istio-system istiod
IMG=$(kubectl get deploy -n istio-system istiod -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[[ "$IMG" == *":$ISTIO_VERSION"* ]] && pass "istiod image $IMG" || fail "istiod image '$IMG' is not $ISTIO_VERSION"
for crd in gateways.networking.istio.io virtualservices.networking.istio.io destinationrules.networking.istio.io; do
    kubectl get crd "$crd" >/dev/null 2>&1 && pass "CRD $crd" || fail "CRD $crd missing"
done
ALOG=$(kubectl get configmap -n istio-system istio -o jsonpath='{.data.mesh}' 2>/dev/null | grep accessLogFile)
[[ "$ALOG" == *"/dev/stdout"* ]] && pass "mesh accessLogFile /dev/stdout" || fail "mesh accessLogFile not /dev/stdout"

section "Ingress gateway"
check_workload deployment istio-ingress istio-ingress
check "ingress pod label istio=ingressgateway" "ingressgateway" \
    "$(kubectl get deploy -n istio-ingress istio-ingress -o jsonpath='{.spec.template.metadata.labels.istio}')"
PORTS=$(kubectl get svc -n istio-ingress istio-ingress -o json 2>/dev/null \
        | jq -r '[.spec.ports[] | "\(.name):\(.port)->\(.targetPort)"] | join(" ")')
check "ingress service ports" "status-port:15021->15021 http2:80->8080 https:443->443" "$PORTS"
check "ingress NLB scheme annotation" "internal" \
    "$(kubectl get svc -n istio-ingress istio-ingress -o jsonpath='{.metadata.annotations.service\.beta\.kubernetes\.io/aws-load-balancer-scheme}')"
check_internal_nlb istio-ingress istio-ingress
GW_HOST="${LB_HOST:-}"

# ------------------------------------------------------------------ bookinfo
section "Bookinfo (namespace sample)"
if check_ns sample; then
    check "sidecar injection label" "enabled" "$(kubectl get ns sample -o jsonpath='{.metadata.labels.istio-injection}')"
    for d in $BOOK_DEPLOYMENTS; do check_workload deployment sample "$d"; done
    for s in $BOOK_SERVICES; do kubectl get svc -n sample "$s" >/dev/null 2>&1 && pass "service $s" || fail "service $s missing"; done
    check_all_pods sample
    NOPROXY=$(kubectl get pods -n sample -o json | jq -r '.items[] | select([.spec.containers[].name, .spec.initContainers[]?.name] | index("istio-proxy") | not) | .metadata.name' | tr '\n' ' ')
    [[ -z "$NOPROXY" ]] && pass "every sample pod has the istio-proxy sidecar" || fail "pods without istio-proxy: $NOPROXY"
    kubectl get gateway.networking.istio.io -n sample bookinfo-gateway >/dev/null 2>&1 && pass "Gateway bookinfo-gateway" || fail "Gateway bookinfo-gateway missing"
    kubectl get virtualservice.networking.istio.io -n sample bookinfo >/dev/null 2>&1 && pass "VirtualService bookinfo" || fail "VirtualService bookinfo missing"

    section "End-to-end requests (curl from the ratings pod)"
    RP=$(kubectl get pod -n sample -l app=ratings -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [[ -z "$RP" ]]; then fail "no ratings pod to run curl from"; else
        T=$(kubectl exec -n sample "$RP" -c ratings -- curl -sS --max-time 10 productpage:9080/productpage 2>/dev/null | grep -o '<title>.*</title>')
        check "in-mesh productpage title" "<title>Simple Bookstore App</title>" "$T"
        T=$(kubectl exec -n sample "$RP" -c ratings -- curl -sS --max-time 10 http://istio-ingress.istio-ingress.svc.cluster.local/productpage 2>/dev/null | grep -o '<title>.*</title>')
        check "productpage via ingress gateway (Gateway + VirtualService)" "<title>Simple Bookstore App</title>" "$T"
        NF=$(kubectl exec -n sample "$RP" -c ratings -- curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://istio-ingress.istio-ingress.svc.cluster.local/not-routed 2>/dev/null)
        check "unrouted path via gateway returns 404" "404" "$NF"
    fi
    if command -v curl >/dev/null && [[ -n "$GW_HOST" ]]; then
        code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://$GW_HOST/productpage" || true)
        if [[ "$code" == "200" ]]; then pass "http://$GW_HOST/productpage returns 200"
        else warn "http://$GW_HOST/productpage returned '$code' (internal NLB - only reachable from the VPC / IDE instance)"; fi
    fi
    if command -v istioctl >/dev/null; then
        if OUT=$(istioctl analyze -n sample 2>&1) && [[ "$OUT" != *"Error"* ]]; then pass "istioctl analyze -n sample: no errors"
        else fail "istioctl analyze -n sample reported errors"; echo "$OUT" | sed 's/^/        /'; fi
    else
        info "istioctl not installed - analyze skipped"
    fi
fi

summary
