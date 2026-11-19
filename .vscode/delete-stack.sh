#!/usr/bin/env bash
#
# Delete the IDE environment: the CloudFront distribution and VPC origin created by
# cre-origin.sh, then the CloudFormation stack, then restore the default VPC's Name tag.
#
# Refuses to run while the workshop stages are still deployed: the net stage adds routes and
# security-group rules to resources in this stack and peers with this VPC.
#
# Usage:
#   ./delete-stack.sh           # asks for confirmation
#   ./delete-stack.sh --yes     # no prompt
#   ./delete-stack.sh --force   # skip the "workshop still deployed" check (also asks)
#
# Settings (environment): AWS_REGION (eu-west-2), STACK (vscode), ORIGIN_NAME (vscode-ide-origin),
#                         VPC_TAG (eksworkshop-vpc)
#
set -euo pipefail

export AWS_REGION="${AWS_REGION:-eu-west-2}"
export AWS_DEFAULT_REGION="$AWS_REGION"
STACK="${STACK:-vscode}"
ORIGIN_NAME="${ORIGIN_NAME:-vscode-ide-origin}"
VPC_TAG="${VPC_TAG:-eksworkshop-vpc}"
COMMENT="vscode distribution with VPC Origin"

ASSUME_YES=0; FORCE=0
for a in "$@"; do
    case "$a" in
        --yes|-y) ASSUME_YES=1 ;;
        --force)  FORCE=1 ;;
        *) echo "unknown option $a"; exit 1 ;;
    esac
done

log() { echo "[$(date '+%H:%M:%S')] $*"; }
die() { log "ERROR: $*"; exit 1; }

command -v aws >/dev/null || die "aws CLI not found"
command -v jq  >/dev/null || die "jq not found"
ARN=$(aws sts get-caller-identity --query Arn --output text) || die "no working AWS credentials"

status=$(aws cloudformation describe-stacks --stack-name "$STACK" \
         --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo NONE)
DIST_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='$COMMENT'].Id | [0]" --output text)
VO_ID=$(aws cloudfront list-vpc-origins --query "VpcOriginList.Items[?Name=='$ORIGIN_NAME'].Id | [0]" --output text 2>/dev/null || echo None)
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_TAG" --query 'Vpcs[0].VpcId' --output text)

log "identity     : $ARN"
log "region       : $AWS_REGION"
log "stack        : $STACK ($status)"
log "distribution : ${DIST_ID/None/<none>}"
log "VPC origin   : ${VO_ID/None/<none>}"
log "tagged VPC   : ${VPC_ID/None/<none>}"

# ------------------------------------------------------------------ workshop still deployed?
if [[ $FORCE -ne 1 ]]; then
    if aws ssm get-parameter --name /workshop/tf-eks/bucket-name >/dev/null 2>&1; then
        die "the workshop stages are still deployed (SSM /workshop/tf-eks/* exists) - run
       .aws-staff/destroy-everything.sh first, or use --force"
    fi
    if [[ "$VPC_ID" == vpc-* ]]; then
        # The net stage peers this VPC (requester) with the EKS VPC (accepter, tagged workshop=tf-eks).
        # Other peerings on the default VPC (e.g. Lightsail) are not the workshop's and are ignored.
        accepters=$(aws ec2 describe-vpc-peering-connections \
            --filters "Name=status-code,Values=active,pending-acceptance" "Name=requester-vpc-info.vpc-id,Values=$VPC_ID" \
            --query 'VpcPeeringConnections[].AccepterVpcInfo.VpcId' --output text)
        if [[ -n "$accepters" ]]; then
            # shellcheck disable=SC2086  # word-splitting the VPC id list is intended
            ws=$(aws ec2 describe-vpcs --vpc-ids $accepters --filters Name=tag:workshop,Values=tf-eks \
                 --query 'length(Vpcs)' --output text 2>/dev/null || echo 0)
            [[ "$ws" -eq 0 ]] || die "the IDE VPC is still peered with the workshop EKS VPC (net stage) - destroy the workshop first, or use --force"
        fi
    fi
fi

if [[ $ASSUME_YES -ne 1 ]]; then
    read -r -p "Delete the IDE environment above? Type 'delete' to continue: " answer
    [[ "$answer" == "delete" ]] || { log "aborted"; exit 1; }
fi

# ------------------------------------------------------------------ CloudFront distribution
if [[ "$DIST_ID" != "None" && -n "$DIST_ID" ]]; then
    CFG=$(mktemp); trap 'rm -f "$CFG"' EXIT
    etag=$(aws cloudfront get-distribution-config --id "$DIST_ID" --query ETag --output text)
    enabled=$(aws cloudfront get-distribution-config --id "$DIST_ID" --query DistributionConfig.Enabled --output text)
    if [[ "$enabled" == "True" ]]; then
        log "disabling distribution $DIST_ID"
        aws cloudfront get-distribution-config --id "$DIST_ID" --query DistributionConfig --output json \
            | jq '.Enabled = false' > "$CFG"
        etag=$(aws cloudfront update-distribution --id "$DIST_ID" --if-match "$etag" \
               --distribution-config "file://$CFG" --query ETag --output text)
    fi
    log "waiting for distribution $DIST_ID to finish deploying (~5-15 minutes)"
    aws cloudfront wait distribution-deployed --id "$DIST_ID" || die "distribution $DIST_ID did not deploy"
    etag=$(aws cloudfront get-distribution --id "$DIST_ID" --query ETag --output text)
    aws cloudfront delete-distribution --id "$DIST_ID" --if-match "$etag"
    log "deleted distribution $DIST_ID"
fi

# ------------------------------------------------------------------ VPC origin
if [[ "$VO_ID" != "None" && -n "$VO_ID" ]]; then
    etag=$(aws cloudfront get-vpc-origin --id "$VO_ID" --query ETag --output text)
    aws cloudfront delete-vpc-origin --id "$VO_ID" --if-match "$etag" >/dev/null
    log "deleting VPC origin $VO_ID"
    for _ in $(seq 1 90); do
        aws cloudfront get-vpc-origin --id "$VO_ID" >/dev/null 2>&1 || break
        sleep 10
    done
    aws cloudfront get-vpc-origin --id "$VO_ID" >/dev/null 2>&1 && die "VPC origin $VO_ID still exists after 15 minutes"
    log "VPC origin $VO_ID deleted"
fi

# ------------------------------------------------------------------ stack
if [[ "$status" != "NONE" ]]; then
    log "deleting stack $STACK (~10 minutes)"
    aws cloudformation delete-stack --stack-name "$STACK"
    aws cloudformation wait stack-delete-complete --stack-name "$STACK" || die "stack $STACK did not delete - check its events"
    log "stack $STACK deleted"
fi

# ------------------------------------------------------------------ restore the default VPC's Name tag
if [[ "$VPC_ID" == vpc-* ]]; then
    prev=$(aws ec2 describe-vpcs --vpc-ids "$VPC_ID" \
           --query "Vpcs[0].Tags[?Key=='eksworkshop:previous-name']|[0].Value" --output text)
    if [[ "$prev" != "None" && -n "$prev" ]]; then
        aws ec2 create-tags --resources "$VPC_ID" --tags "Key=Name,Value=$prev"
        aws ec2 delete-tags --resources "$VPC_ID" --tags "Key=eksworkshop:previous-name"
        log "restored $VPC_ID Name=$prev"
    else
        aws ec2 delete-tags --resources "$VPC_ID" --tags "Key=Name,Value=$VPC_TAG"
        log "removed Name=$VPC_TAG from $VPC_ID"
    fi
fi
log "done"
