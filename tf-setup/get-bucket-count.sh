#!/bin/bash
# Exit if any of the intermediate steps fail
set -e
BUCKET_COUNT=0
res=`terraform state list aws_s3_bucket.terraform_state`
if [[ $? .eq 1 ]]; then 
BUCKET_COUNT=1
fi
echo "count=$BUCKET_COUNT"
jq -n --arg bc "$BUCKET_COUNT" '{"Name":$bc}'

