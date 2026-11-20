#!/usr/bin/env bash
#
# Publish the IDE instance's code-server (port 80, nginx) through CloudFront using a VPC origin,
# so the private instance is reachable at https://<id>.cloudfront.net.
#
# NOTE: this makes the code-server login page reachable from the internet. Access is protected
# only by the code-server password (see ./get-url.sh), and the instance role has
# AdministratorAccess. The instance security group only admits CloudFront (origin-facing prefix list).
#
# Usage:
#   ./cre-origin.sh             # create (or reuse) the VPC origin and distribution
#   ./cre-origin.sh --dry-run   # resolve everything and print what would be created
#
# Settings (environment): AWS_REGION (eu-west-1), INSTANCE_NAME (eksworkshop-kiroide),
#                         ORIGIN_NAME (vscode-ide-origin)
#
set -euo pipefail

export AWS_REGION="${AWS_REGION:-eu-west-1}"
export AWS_DEFAULT_REGION="$AWS_REGION"
INSTANCE_NAME="${INSTANCE_NAME:-eksworkshop-kiroide}"
ORIGIN_NAME="${ORIGIN_NAME:-vscode-ide-origin}"
COMMENT="vscode distribution with VPC Origin"   # get-url.sh / delete-stack.sh find the distribution by this

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

log() { echo "[$(date '+%H:%M:%S')] $*"; }
die() { log "ERROR: $*"; exit 1; }

command -v aws >/dev/null || die "aws CLI not found"
command -v jq  >/dev/null || die "jq not found"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) || die "no working AWS credentials"

# ------------------------------------------------------------------ instance
read -r IID PDNS < <(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$INSTANCE_NAME" Name=instance-state-name,Values=running \
    --query 'Reservations[0].Instances[0].[InstanceId,PrivateDnsName]' --output text)
[[ "$IID" == i-* ]] || die "no running instance tagged Name=$INSTANCE_NAME in $AWS_REGION (deploy-stack.sh first)"
INSTANCE_ARN="arn:aws:ec2:${AWS_REGION}:${ACCOUNT_ID}:instance/${IID}"
log "instance: $IID ($PDNS)"

# ------------------------------------------------------------------ existing distribution?
DIST_ID=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Comment=='$COMMENT'].Id | [0]" --output text)
if [[ "$DIST_ID" != "None" && -n "$DIST_ID" ]]; then
    origin=$(aws cloudfront get-distribution --id "$DIST_ID" \
             --query 'Distribution.DistributionConfig.Origins.Items[0].DomainName' --output text)
    log "distribution $DIST_ID already exists (origin $origin)"
    [[ "$origin" == "$PDNS" ]] || log "WARNING: its origin is not this instance ($PDNS) - delete it and re-run"
    exit 0
fi

# ------------------------------------------------------------------ VPC origin (reuse by name)
VPC_ORIGIN_ID=$(aws cloudfront list-vpc-origins \
    --query "VpcOriginList.Items[?Name=='$ORIGIN_NAME'].Id | [0]" --output text 2>/dev/null || echo None)

if [[ $DRY_RUN -eq 1 ]]; then
    log "dry run: instance ARN       $INSTANCE_ARN"
    log "dry run: VPC origin         ${VPC_ORIGIN_ID/None/<would create $ORIGIN_NAME>}"
    log "dry run: distribution       <would create, comment '$COMMENT', origin $PDNS>"
    exit 0
fi

if [[ "$VPC_ORIGIN_ID" == "None" || -z "$VPC_ORIGIN_ID" ]]; then
    log "creating VPC origin $ORIGIN_NAME"
    VPC_ORIGIN_ID=$(aws cloudfront create-vpc-origin \
        --vpc-origin-endpoint-config "{\"Name\":\"$ORIGIN_NAME\",\"Arn\":\"$INSTANCE_ARN\",\"HTTPPort\":80,\"HTTPSPort\":443,\"OriginProtocolPolicy\":\"http-only\"}" \
        --query VpcOrigin.Id --output text)
else
    log "reusing VPC origin $VPC_ORIGIN_ID"
fi

log "waiting for VPC origin $VPC_ORIGIN_ID to be Deployed (can take ~15 minutes)"
for i in $(seq 1 120); do
    st=$(aws cloudfront get-vpc-origin --id "$VPC_ORIGIN_ID" --query VpcOrigin.Status --output text)
    [[ "$st" == "Deployed" ]] && break
    [[ $((i % 6)) -eq 0 ]] && log "  status: $st"
    sleep 10
done
[[ "$st" == "Deployed" ]] || die "VPC origin still $st after 20 minutes"

# ------------------------------------------------------------------ distribution
CFG=$(mktemp)
trap 'rm -f "$CFG"' EXIT
jq -n --arg ref "vscode-$(date +%s)" --arg comment "$COMMENT" --arg dns "$PDNS" --arg vo "$VPC_ORIGIN_ID" '{
  CallerReference: $ref,
  Comment: $comment,
  Enabled: true,
  PriceClass: "PriceClass_All",
  Origins: { Quantity: 1, Items: [{
    Id: "MyVPCOrigin",
    DomainName: $dns,
    VpcOriginConfig: { VpcOriginId: $vo },
    OriginCustomHeaders: { Quantity: 0 },
    ConnectionAttempts: 3,
    ConnectionTimeout: 10
  }]},
  DefaultCacheBehavior: {
    TargetOriginId: "MyVPCOrigin",
    ViewerProtocolPolicy: "redirect-to-https",
    AllowedMethods: { Quantity: 7, Items: ["GET","HEAD","OPTIONS","PUT","POST","PATCH","DELETE"],
                      CachedMethods: { Quantity: 2, Items: ["GET","HEAD"] } },
    CachePolicyId: "4135ea2d-6df8-44a3-9df3-4b5a84be39ad",
    OriginRequestPolicyId: "216adef6-5c7f-47e4-b989-5492eafa07d3",
    Compress: true,
    LambdaFunctionAssociations: { Quantity: 0 },
    FunctionAssociations: { Quantity: 0 }
  }
}' > "$CFG"
# CachePolicyId 4135ea2d... = Managed-CachingDisabled; OriginRequestPolicyId 216adef6... = Managed-AllViewer
# (code-server needs every header/cookie and websockets passed through, nothing cached)

log "creating CloudFront distribution"
read -r DIST_ID DOMAIN < <(aws cloudfront create-distribution --distribution-config "file://$CFG" \
    --query 'Distribution.[Id,DomainName]' --output text)
log "distribution $DIST_ID ($DOMAIN) - waiting for it to deploy (~5-10 minutes)"
aws cloudfront wait distribution-deployed --id "$DIST_ID" || die "distribution $DIST_ID did not finish deploying"
log "done - run ./get-url.sh for the URL and password"
