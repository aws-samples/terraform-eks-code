#!/usr/bin/env bash
#
# Deploy the IDE environment (code-server on EC2) that the workshop runs from.
#
# Usage:
#   ./deploy-stack.sh                        # create the stack and wait for it
#   ./deploy-stack.sh --delete-orphan-role   # first delete a leftover eksworkshop-admin role
#                                            # (only when no stack exists, e.g. after a failed create)
#
# Settings (override with environment variables):
#   AWS_REGION     default eu-west-1
#   STACK          default vscode
#   INSTANCE_NAME  default eksworkshop-kiroide   (the net stage looks the instance up by this Name tag)
#   VPC_TAG        default eksworkshop-vpc       (the net stage looks the default VPC up by this Name tag)
#
# Next steps afterwards: ./cre-origin.sh (CloudFront access), then ./get-url.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AWS_REGION="${AWS_REGION:-eu-west-1}"
export AWS_DEFAULT_REGION="$AWS_REGION"
STACK="${STACK:-vscode}"
INSTANCE_NAME="${INSTANCE_NAME:-eksworkshop-kiroide}"
VPC_TAG="${VPC_TAG:-eksworkshop-vpc}"
TEMPLATE="$SCRIPT_DIR/vscode-isengard.yaml"
ROLE=eksworkshop-admin   # RoleName fixed in the template

DELETE_ORPHAN_ROLE=0
[[ "${1:-}" == "--delete-orphan-role" ]] && DELETE_ORPHAN_ROLE=1

log() { echo "[$(date '+%H:%M:%S')] $*"; }
die() { log "ERROR: $*"; exit 1; }

command -v aws >/dev/null || die "aws CLI not found"
[[ -f "$TEMPLATE" ]] || die "template $TEMPLATE not found"
ARN=$(aws sts get-caller-identity --query Arn --output text) || die "no working AWS credentials"
log "identity: $ARN  region: $AWS_REGION  stack: $STACK  instance name: $INSTANCE_NAME"

# ------------------------------------------------------------------ existing stack?
status=$(aws cloudformation describe-stacks --stack-name "$STACK" \
         --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo NONE)
case "$status" in
    NONE) ;;
    CREATE_COMPLETE|UPDATE_COMPLETE)
        log "stack $STACK already exists ($status) - nothing to do"; exit 0 ;;
    *)
        die "stack $STACK exists in state $status - fix or delete it first (./delete-stack.sh)" ;;
esac

# ------------------------------------------------------------------ leftover IAM role
# The template creates a *named* role, so a role left by a failed/partial create blocks a new stack.
if aws iam get-role --role-name "$ROLE" >/dev/null 2>&1; then
    if [[ $DELETE_ORPHAN_ROLE -ne 1 ]]; then
        die "IAM role $ROLE already exists and no $STACK stack does. If it is left over from an
       earlier failed deploy, re-run with --delete-orphan-role to remove it."
    fi
    log "deleting orphaned role $ROLE"
    for p in $(aws iam list-attached-role-policies --role-name "$ROLE" --query 'AttachedPolicies[].PolicyArn' --output text); do
        aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$p"
    done
    for p in $(aws iam list-role-policies --role-name "$ROLE" --query 'PolicyNames' --output text); do
        aws iam delete-role-policy --role-name "$ROLE" --policy-name "$p"
    done
    for ip in $(aws iam list-instance-profiles-for-role --role-name "$ROLE" --query 'InstanceProfiles[].InstanceProfileName' --output text); do
        aws iam remove-role-from-instance-profile --instance-profile-name "$ip" --role-name "$ROLE"
    done
    aws iam delete-role --role-name "$ROLE"
fi

# ------------------------------------------------------------------ create
VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)
[[ "$VPC_ID" == vpc-* ]] || die "no default VPC in $AWS_REGION"
log "default VPC: $VPC_ID"

log "creating stack $STACK (~10 minutes)"
aws cloudformation create-stack --stack-name "$STACK" \
    --template-body "file://$TEMPLATE" \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameters "ParameterKey=DefaultVpcId,ParameterValue=$VPC_ID" \
                 "ParameterKey=InstanceName,ParameterValue=$INSTANCE_NAME" \
    --query StackId --output text

if ! aws cloudformation wait stack-create-complete --stack-name "$STACK"; then
    log "stack create failed - first failure reasons:"
    aws cloudformation describe-stack-events --stack-name "$STACK" \
        --query "StackEvents[?ResourceStatus=='CREATE_FAILED'].[LogicalResourceId,ResourceStatusReason]" \
        --output text | tail -5
    die "stack $STACK did not create"
fi
log "stack $STACK: CREATE_COMPLETE"

# ------------------------------------------------------------------ tag the default VPC for the net stage
prev=$(aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query "Vpcs[0].Tags[?Key=='Name']|[0].Value" --output text)
if [[ "$prev" != "$VPC_TAG" ]]; then
    # remember the original Name so delete-stack.sh can put it back
    [[ "$prev" != "None" ]] && aws ec2 create-tags --resources "$VPC_ID" --tags "Key=eksworkshop:previous-name,Value=$prev"
    aws ec2 create-tags --resources "$VPC_ID" --tags "Key=Name,Value=$VPC_TAG"
    log "tagged $VPC_ID Name=$VPC_TAG (was: $prev)"
fi

log "done - next: ./cre-origin.sh to publish code-server through CloudFront, then ./get-url.sh"
