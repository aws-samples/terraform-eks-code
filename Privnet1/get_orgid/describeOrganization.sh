#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

ORGID=$(aws organizations describe-organization $( if [ -n "$AWS_PROFILE" ];then printf %s "--profile=$AWS_PROFILE"; fi) --query 'Organization.Id' --output text)

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg orgid "$ORGID" '{"Id":$orgid}'
