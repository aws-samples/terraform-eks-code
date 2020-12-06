#!/bin/bash
# Exit if any of the intermediate steps fail
set -e
BUCKET_COUNT=0
res=`terraform state list aws_s3_bucket.terraform_state || true`
if [[ "$res" == "" ]]; then
BUCKET_COUNT=1
fi
jq -n --arg bc "$BUCKET_COUNT" '{"Count":$bc}'

