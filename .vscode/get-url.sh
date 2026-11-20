#!/usr/bin/env bash
#
# Print the code-server URL (CloudFront) and password for the IDE instance.
#
# Settings (environment): AWS_REGION (eu-west-1), STACK (vscode), INSTANCE_NAME (eksworkshop-kiroide)
#
set -euo pipefail

export AWS_REGION="${AWS_REGION:-eu-west-1}"
export AWS_DEFAULT_REGION="$AWS_REGION"
STACK="${STACK:-vscode}"
INSTANCE_NAME="${INSTANCE_NAME:-eksworkshop-kiroide}"
COMMENT="vscode distribution with VPC Origin"   # set by cre-origin.sh

die() { echo "ERROR: $*" >&2; exit 1; }

command -v aws >/dev/null || die "aws CLI not found"

read -r IID PDNS < <(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$INSTANCE_NAME" Name=instance-state-name,Values=running \
    --query 'Reservations[0].Instances[0].[InstanceId,PrivateDnsName]' --output text)
[[ "$IID" == i-* ]] || die "no running instance tagged Name=$INSTANCE_NAME in $AWS_REGION"
echo "instance : $IID ($PDNS)"

# Only the IDE's distribution - the account can hold others
read -r DIST_ID DOMAIN ORIGIN < <(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Comment=='$COMMENT'] | [0].[Id,DomainName,Origins.Items[0].DomainName]" \
    --output text)
[[ "$DIST_ID" != "None" && -n "$DIST_ID" ]] || die "no CloudFront distribution with comment '$COMMENT' - run ./cre-origin.sh"
[[ "$ORIGIN" == "$PDNS" ]] || echo "WARNING: distribution $DIST_ID points at $ORIGIN, not this instance ($PDNS)"

FOLDER=$(aws cloudformation describe-stacks --stack-name "$STACK" \
    --query "Stacks[0].Parameters[?ParameterKey=='HomeFolder'].ParameterValue | [0]" --output text)
PASSWORD=$(aws cloudformation describe-stacks --stack-name "$STACK" \
    --query "Stacks[0].Outputs[?OutputKey=='Password'].OutputValue | [0]" --output text)

echo "url      : https://$DOMAIN/?folder=$FOLDER"
echo "password : $PASSWORD"
