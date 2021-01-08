#!/bin/bash
# Exit if any of the intermediate steps fail
set -e
t2=`date +%s%N`
t1=`hostname | cut -f1 -d'.'`
BUCKET_NAME=`printf "codep-tfeks-%s-%s" $t1 $t2 | awk '{print tolower($0)}'`
jq -n --arg bn "$BUCKET_NAME" '{"Name":$bn}'