#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

# Extract arguments from the input into shell variables.
# jq will ensure that the values are properly quoted
# and escaped for consumption by the shell.
eval "$(jq -r '@sh "PARENT=\(.parent_id) SEARCH=\(.ou_name) AWS_PROFILE=\(.profile)"')"

list_of_OU_ids=()
list_of_OU_names=()

function traverse_organization {

    local list_of_OUs_response=$(aws organizations list-organizational-units-for-parent --parent-id $1 --max-items 20 $( if [ -n "$AWS_PROFILE" ];then printf %s "--profile=$AWS_PROFILE"; fi))

    if [[ $list_of_OUs_response == *"OrganizationalUnits"* ]]; then
        for ou in $(jq --compact-output '.OrganizationalUnits[]' <<< "$list_of_OUs_response"); do
            local Id=$(jq --raw-output '.Id' <<< "$ou")
            list_of_OU_ids+=($Id)
            list_of_OU_names+=($(jq --raw-output '.Name' <<< "$ou"))
            traverse_organization $Id
        done
    fi
}

traverse_organization $PARENT

OUID=0

for i in "${!list_of_OU_names[@]}"; do
   if [[ "${list_of_OU_names[$i]}" == "$SEARCH" ]]; then
       OUID="${list_of_OU_ids[$i]}";
   fi
done

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg ouid "$OUID" '{"Id":$ouid}'