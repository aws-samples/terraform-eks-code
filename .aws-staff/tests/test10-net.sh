#!/usr/bin/env bash
#
# Validate the net stage: EKS VPC (terraform-aws-modules/vpc), subnets, NAT, flow logs,
# VPC endpoints, peering to the IDE (default) VPC and its routes, IDE security group rules,
# the Route 53 zone and the SSM parameters later stages read.
# No Kubernetes objects are created by this stage, so kubectl is not used.
#
# Usage: ./test10-net.sh    Needs: aws, jq. Read-only.
#
set -uo pipefail
# shellcheck source=lib-test.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib-test.sh"

VPC_CIDR="10.141.0.0/16"
SEC_CIDR="100.65.0.0/16"
ENDPOINTS="autoscaling ecr.api ecr.dkr ec2 guardduty-data ec2messages sts logs ssm ssmmessages grafana grafana-workspace secretsmanager"
DN="people.aws.dev"

section "AWS identity and tf-setup parameters"
setup_aws
load_setup_params
check_state_file net

# ------------------------------------------------------------------ SSM
section "SSM parameters written by net"
check_ssm eks-vpc;   VPC="$SSM_VALUE"
check_ssm cicd-vpc;  check "cicd-vpc = eks-vpc" "$VPC" "$SSM_VALUE"
check_ssm eks-cidr;  check "eks-cidr" "$VPC_CIDR" "$SSM_VALUE"
check_ssm cicd-cidr; check "cicd-cidr" "$VPC_CIDR" "$SSM_VALUE"
check_ssm private_subnets StringList; PRIV=$(echo "$SSM_VALUE" | jq -r '.[]' 2>/dev/null)
check_ssm intra_subnets StringList;   INTRA=$(echo "$SSM_VALUE" | jq -r '.[]' 2>/dev/null)
check_ssm private_rtb; PRIV_RTB="$SSM_VALUE"
check_ssm intra_rtb;   INTRA_RTB="$SSM_VALUE"
check_ssm public_rtb;  PUB_RTB="$SSM_VALUE"
check_ssm phz-id;      PHZ="$SSM_VALUE"
[[ -n "$VPC" ]] || abort "eks-vpc parameter missing - net not applied"

# ------------------------------------------------------------------ VPC
section "EKS VPC $VPC"
V=$(aws ec2 describe-vpcs --vpc-ids "$VPC" --output json 2>/dev/null | jq '.Vpcs[0]')
[[ -n "$V" && "$V" != "null" ]] || abort "VPC $VPC not found"
check "VPC state" "available" "$(echo "$V" | jq -r .State)"
check "VPC primary CIDR" "$VPC_CIDR" "$(echo "$V" | jq -r .CidrBlock)"
check "secondary CIDR associated" "associated" \
    "$(echo "$V" | jq -r --arg c "$SEC_CIDR" '.CidrBlockAssociationSet[] | select(.CidrBlock==$c) | .CidrBlockState.State')"
check "VPC Name tag" "$CLUSTER_PARAM" "$(echo "$V" | jq -r '.Tags[]? | select(.Key=="Name") | .Value')"
check "VPC tag workshop" "tf-eks" "$(echo "$V" | jq -r '.Tags[]? | select(.Key=="workshop") | .Value')"
check "DNS support" "True" "$(aws ec2 describe-vpc-attribute --vpc-id "$VPC" --attribute enableDnsSupport --query EnableDnsSupport.Value --output text)"
check "DNS hostnames" "True" "$(aws ec2 describe-vpc-attribute --vpc-id "$VPC" --attribute enableDnsHostnames --query EnableDnsHostnames.Value --output text)"

# ------------------------------------------------------------------ subnets
section "Subnets"
SUBS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC" --output json | jq '.Subnets')
check "subnet count (3 public, 3 private, 3 intra)" "9" "$(echo "$SUBS" | jq length)"
tagval() { echo "$SUBS" | jq -r --arg s "$1" --arg k "$2" '.[] | select(.SubnetId==$s) | .Tags[]? | select(.Key==$k) | .Value'; }
cidr()   { echo "$SUBS" | jq -r --arg s "$1" '.[] | select(.SubnetId==$s) | .CidrBlock'; }
az()     { echo "$SUBS" | jq -r --arg s "$1" '.[] | select(.SubnetId==$s) | .AvailabilityZone'; }
n=0; azs=""
for s in $PRIV; do
    n=$((n+1)); c=$(cidr "$s"); azs="$azs $(az "$s")"
    [[ "$c" == 100.65.* ]] && pass "private $s $c in secondary CIDR" || fail "private $s CIDR '$c' not in $SEC_CIDR"
    [[ "$(tagval "$s" kubernetes.io/role/internal-elb)" == "1" && "$(tagval "$s" karpenter.sh/discovery)" == "$CLUSTER_PARAM" ]] \
        && pass "private $s has internal-elb and karpenter.sh/discovery tags" || fail "private $s missing internal-elb / karpenter.sh/discovery tags"
done
check "private subnets" "3" "$n"
check "private subnets span distinct AZs" "3" "$(echo "$azs" | tr ' ' '\n' | grep . | sort -u | wc -l | tr -d ' ')"
n=0
for s in $INTRA; do
    n=$((n+1)); c=$(cidr "$s")
    [[ "$c" =~ ^10\.141\.5[234]\.0/24$ ]] && pass "intra $s $c" || fail "intra $s CIDR '$c' (expected 10.141.52-54.0/24)"
done
check "intra subnets" "3" "$n"
PUBS=$(echo "$SUBS" | jq -r '.[] | select(.Tags[]? | .Key=="kubernetes.io/role/elb" and .Value=="1") | .CidrBlock' | sort | tr '\n' ' ')
check "public subnets (kubernetes.io/role/elb=1)" "10.141.48.0/24 10.141.49.0/24 10.141.50.0/24 " "$PUBS"

# ------------------------------------------------------------------ gateways and routes
section "Internet / NAT gateways and route tables"
IGW=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC" --query 'InternetGateways[0].InternetGatewayId' --output text)
[[ "$IGW" == igw-* ]] && pass "internet gateway $IGW attached" || fail "no internet gateway attached"
NATS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC" "Name=state,Values=available" --query 'NatGateways[].NatGatewayId' --output text)
check "available NAT gateways (single_nat_gateway)" "1" "$(echo "$NATS" | wc -w | tr -d ' ')"
route_target() {  # route_target <rtb> <cidr> -> gateway/nat/peering id
    aws ec2 describe-route-tables --route-table-ids "$1" --output json 2>/dev/null | jq -r --arg c "$2" \
      '.RouteTables[0].Routes[] | select(.DestinationCidrBlock==$c) | select(.State=="active") | (.NatGatewayId // .GatewayId // .VpcPeeringConnectionId)'
}
check "public rtb default route -> IGW" "$IGW" "$(route_target "$PUB_RTB" 0.0.0.0/0)"
[[ "$(route_target "$PRIV_RTB" 0.0.0.0/0)" == nat-* ]] && pass "private rtb default route -> NAT" || fail "private rtb has no active default route to the NAT gateway"
# public/intra route tables must be associated with the matching subnets
for s in $PRIV; do
    check "private subnet $s uses private rtb" "$PRIV_RTB" \
        "$(aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$s" --query 'RouteTables[0].RouteTableId' --output text)"
done
for s in $INTRA; do
    check "intra subnet $s uses intra rtb" "$INTRA_RTB" \
        "$(aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$s" --query 'RouteTables[0].RouteTableId' --output text)"
done
DEF_RT=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC" "Name=association.main,Values=true" --output json | jq '.RouteTables[0]')
check "default route table Name tag" "${CLUSTER_PARAM}-default" "$(echo "$DEF_RT" | jq -r '.Tags[]? | select(.Key=="Name") | .Value')"
DEF_ACL=$(aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$VPC" "Name=default,Values=true" --output json | jq '.NetworkAcls[0]')
check "default network ACL Name tag" "${CLUSTER_PARAM}-default" "$(echo "$DEF_ACL" | jq -r '.Tags[]? | select(.Key=="Name") | .Value')"

# ------------------------------------------------------------------ flow logs
section "VPC flow logs"
FL=$(aws ec2 describe-flow-logs --filter "Name=resource-id,Values=$VPC" --output json | jq '.FlowLogs[0]')
if [[ "$FL" == "null" ]]; then fail "no flow log on $VPC"; else
    check "flow log status" "ACTIVE" "$(echo "$FL" | jq -r .FlowLogStatus)"
    check "flow log destination" "cloud-watch-logs" "$(echo "$FL" | jq -r .LogDestinationType)"
    LG=$(echo "$FL" | jq -r .LogGroupName)
    check "flow log group $LG retention days" "7" \
        "$(aws logs describe-log-groups --log-group-name-prefix "$LG" --query "logGroups[?logGroupName=='$LG'].retentionInDays | [0]" --output text)"
fi

# ------------------------------------------------------------------ VPC endpoints
section "VPC endpoints"
EPS=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC" --output json | jq '.VpcEndpoints')
S3EP=$(echo "$EPS" | jq -c --arg s "com.amazonaws.$REGION.s3" '.[] | select(.ServiceName==$s and .VpcEndpointType=="Gateway")')
if [[ -n "$S3EP" ]]; then
    check "s3 gateway endpoint state" "available" "$(echo "$S3EP" | jq -r .State)"
    echo "$S3EP" | jq -e --arg r "$INTRA_RTB" '.RouteTableIds | index($r)' >/dev/null \
        && pass "s3 gateway endpoint attached to intra rtb" || fail "s3 gateway endpoint not attached to intra rtb $INTRA_RTB"
else
    fail "s3 gateway endpoint missing"
fi
EP_SG=""
for e in $ENDPOINTS; do
    ep=$(echo "$EPS" | jq -c --arg s "com.amazonaws.$REGION.$e" '.[] | select(.ServiceName==$s and .VpcEndpointType=="Interface")')
    if [[ -z "$ep" ]]; then fail "interface endpoint $e missing"; continue; fi
    st=$(echo "$ep" | jq -r .State); dns=$(echo "$ep" | jq -r .PrivateDnsEnabled); ns=$(echo "$ep" | jq '.SubnetIds | length')
    if [[ "$st" == "available" && "$dns" == "true" && "$ns" -eq 3 ]]; then pass "interface endpoint $e (available, private DNS, 3 subnets)"
    else fail "interface endpoint $e: state=$st privateDns=$dns subnets=$ns"; fi
    EP_SG=$(echo "$ep" | jq -r '.Groups[0].GroupId')
done
if [[ -n "$EP_SG" && "$EP_SG" != "null" ]]; then
    SG=$(aws ec2 describe-security-groups --group-ids "$EP_SG" --output json | jq '.SecurityGroups[0]')
    [[ "$(echo "$SG" | jq -r .GroupName)" == "${CLUSTER_PARAM}-vpc-endpoints-"* ]] && pass "endpoint security group $EP_SG" \
        || fail "endpoint security group name $(echo "$SG" | jq -r .GroupName)"
    for c in "$VPC_CIDR" "$SEC_CIDR"; do
        echo "$SG" | jq -e --arg c "$c" '.IpPermissions[] | select(.FromPort==443 and .ToPort==443) | .IpRanges[] | select(.CidrIp==$c)' >/dev/null \
            && pass "endpoint SG allows 443 from $c" || fail "endpoint SG does not allow 443 from $c"
    done
fi

# ------------------------------------------------------------------ default SG
section "Default security group of the EKS VPC"
DSG=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC" "Name=group-name,Values=default" --output json | jq '.SecurityGroups[0]')
check "default SG Name tag" "${CLUSTER_PARAM}-default" "$(echo "$DSG" | jq -r '.Tags[]? | select(.Key=="Name") | .Value')"
echo "$DSG" | jq -e '.IpPermissions[] | select(.IpProtocol=="-1") | .UserIdGroupPairs[] | select(.GroupId != null)' >/dev/null \
    && pass "default SG ingress: all traffic from itself" || fail "default SG has no self-referencing ingress rule"
check "default SG ingress rule count" "1" "$(echo "$DSG" | jq '.IpPermissions | length')"

# ------------------------------------------------------------------ IDE VPC peering
section "Peering with the IDE VPC (eksworkshop-vpc)"
DEFVPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=eksworkshop-vpc --query 'Vpcs[0].VpcId' --output text)
DEFCIDR=$(aws ec2 describe-vpcs --vpc-ids "$DEFVPC" --query 'Vpcs[0].CidrBlock' --output text 2>/dev/null)
[[ "$DEFVPC" == vpc-* ]] && pass "IDE VPC $DEFVPC ($DEFCIDR)" || abort "IDE VPC tagged eksworkshop-vpc not found"
PEER=$(aws ec2 describe-vpc-peering-connections \
       --filters "Name=requester-vpc-info.vpc-id,Values=$DEFVPC" "Name=accepter-vpc-info.vpc-id,Values=$VPC" "Name=status-code,Values=active" \
       --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' --output text)
[[ "$PEER" == pcx-* ]] && pass "peering $PEER active (IDE VPC -> EKS VPC)" || fail "no active peering from $DEFVPC to $VPC"
check "EKS private rtb: $DEFCIDR -> peering" "$PEER" "$(route_target "$PRIV_RTB" "$DEFCIDR")"
check "EKS intra rtb: $DEFCIDR -> peering" "$PEER" "$(route_target "$INTRA_RTB" "$DEFCIDR")"
IDE_RTB=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=eksworkshop-Private-Routes --query 'RouteTables[0].RouteTableId' --output text)
check "IDE rtb: $VPC_CIDR -> peering" "$PEER" "$(route_target "$IDE_RTB" "$VPC_CIDR")"
check "IDE rtb: $SEC_CIDR -> peering" "$PEER" "$(route_target "$IDE_RTB" "$SEC_CIDR")"

section "IDE security group (kiro1-Instance-SG) rules"
ISG=$(aws ec2 describe-security-groups --filters Name=tag:Name,Values=kiro1-Instance-SG --output json | jq '.SecurityGroups[0]')
if [[ "$ISG" == "null" ]]; then fail "security group tagged kiro1-Instance-SG not found"; else
    for r in "443 $VPC_CIDR" "22 $VPC_CIDR" "8080 $SEC_CIDR" "80 $SEC_CIDR"; do
        set -- $r
        echo "$ISG" | jq -e --argjson p "$1" --arg c "$2" \
            '.IpPermissions[] | select(.IpProtocol=="tcp" and .FromPort==$p and .ToPort==$p) | .IpRanges[] | select(.CidrIp==$c)' >/dev/null \
            && pass "IDE SG allows tcp/$1 from $2" || fail "IDE SG missing tcp/$1 from $2"
    done
fi

# ------------------------------------------------------------------ Route 53
section "Route 53 zone"
Z=$(aws route53 get-hosted-zone --id "$PHZ" --output json 2>/dev/null)
if [[ -z "$Z" ]]; then fail "hosted zone $PHZ not found"; else
    check "zone name" "$ACCOUNT.$TFID.$DN." "$(echo "$Z" | jq -r .HostedZone.Name)"
    info "zone is $( [[ $(echo "$Z" | jq -r .HostedZone.Config.PrivateZone) == true ]] && echo private || echo public )"
fi

summary
