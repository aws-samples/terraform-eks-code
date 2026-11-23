#!/usr/bin/env bash
#
# Validate the tf-setup stage after `terraform apply`.
#
# tf-setup creates:
#   - random_id               -> 16 hex char workshop id
#   - aws_kms_key             -> state encryption key (rotation enabled)
#   - aws_s3_bucket           -> tf-state-workshop-<id>, KMS encrypted, versioned, public access blocked
#   - 7 SSM parameters        -> /workshop/tf-eks/{id,keyid,keyarn,region,cluster-name,bucket-name,eks-version}
#   - gen-backend.sh (local)  -> tf-setup/generated/backend-<stage>.tf + tmp-buck.txt
#
# The later stages read the SSM parameters and use the generated backend files (symlinked
# into each stage directory), so those are checked too. If the EKS cluster already exists,
# the script also checks it matches the cluster-name / eks-version parameters (aws + kubectl).
#
# Usage:  ./test00-tf-setup.sh            (region from AWS_REGION, else the generated backend, else eu-west-1)
# Needs:  aws, jq; terraform and kubectl are optional.
# Exit:   0 when every check passes, 1 otherwise. Read-only: nothing is created or changed
#         (terraform plan is run with -lock=false when tf-setup has local state).
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SETUP="$ROOT/tf-setup"
SECTIONS="tf-setup net cluster nodepool addons observ sampleapp istio"
PARAMS="id keyid keyarn region cluster-name bucket-name eks-version"

PASS=0; FAIL=0; WARN=0
pass() { echo "  PASS  $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL  $*"; FAIL=$((FAIL+1)); }
warn() { echo "  WARN  $*"; WARN=$((WARN+1)); }
info() { echo "  INFO  $*"; }
section() { echo; echo "== $*"; }
# check <description> <expected> <actual>
check() { if [[ "$2" == "$3" ]]; then pass "$1 ($3)"; else fail "$1: expected '$2', got '$3'"; fi; }

for c in aws jq; do
    command -v "$c" >/dev/null || { echo "'$c' not found on PATH"; exit 1; }
done

# ------------------------------------------------------------------ region / identity
section "AWS identity and region"
if [[ -n "${AWS_REGION:-}" ]]; then
    REGION="$AWS_REGION"
elif [[ -f "$SETUP/generated/backend-net.tf" ]]; then
    REGION=$(sed -n 's/^ *region *= *"\(.*\)"/\1/p' "$SETUP/generated/backend-net.tf" | head -1)
fi
REGION="${REGION:-eu-west-1}"
export AWS_REGION="$REGION" AWS_DEFAULT_REGION="$REGION"
if ARN=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null); then
    pass "credentials work: $ARN"
else
    fail "no working AWS credentials"; exit 1
fi
info "region: $REGION"

# ------------------------------------------------------------------ SSM parameters
section "SSM parameters (/workshop/tf-eks/*)"
NAMES=(); for p in $PARAMS; do NAMES+=("/workshop/tf-eks/$p"); done
SSM_JSON=$(aws ssm get-parameters --names "${NAMES[@]}" --output json 2>/dev/null)
if [[ -z "$SSM_JSON" ]]; then
    fail "could not read SSM parameters in $REGION"; exit 1
fi
if [[ $(echo "$SSM_JSON" | jq '.Parameters | length') -eq 0 ]]; then
    fail "no /workshop/tf-eks/* parameters in $REGION - tf-setup is not applied (or AWS_REGION is wrong)"
    exit 1
fi
param() { echo "$SSM_JSON" | jq -r --arg n "/workshop/tf-eks/$1" '.Parameters[] | select(.Name==$n) | .Value'; }
for p in $PARAMS; do
    n="/workshop/tf-eks/$p"
    v=$(param "$p")
    if [[ -z "$v" ]]; then fail "$n missing"; continue; fi
    t=$(echo "$SSM_JSON" | jq -r --arg n "$n" '.Parameters[] | select(.Name==$n) | .Type')
    [[ "$t" == "String" ]] && pass "$n = $v" || fail "$n has type $t (expected String)"
    tag=$(aws ssm list-tags-for-resource --resource-type Parameter --resource-id "$n" \
          --query "TagList[?Key=='workshop'].Value | [0]" --output text 2>/dev/null)
    [[ "$tag" == "tf-eks-workshop" ]] || fail "$n tag workshop=tf-eks-workshop missing (got '$tag')"
done
ID=$(param id); KEYID=$(param keyid); KEYARN=$(param keyarn); BUCKET=$(param bucket-name)
CLUSTER=$(param cluster-name); EKSVER=$(param eks-version)
if [[ -z "$ID" || -z "$KEYID" || -z "$KEYARN" || -z "$BUCKET" || -z "$CLUSTER" || -z "$EKSVER" ]]; then
    echo; echo "== Summary: required parameters missing - cannot continue ($PASS passed, $FAIL failed)"; exit 1
fi
[[ "$ID" =~ ^[0-9a-f]{16}$ ]] && pass "id is 16 hex chars" || fail "id '$ID' is not 16 hex chars"
check "region parameter matches the region in use" "$REGION" "$(param region)"
check "bucket-name is tf-state-workshop-<id>" "tf-state-workshop-$ID" "$BUCKET"
[[ "$KEYARN" == *":key/$KEYID" ]] && pass "keyarn ends with keyid" || fail "keyarn '$KEYARN' does not match keyid '$KEYID'"
[[ "$EKSVER" =~ ^[0-9]+\.[0-9]+$ ]] && pass "eks-version looks like a version" || fail "eks-version '$EKSVER' is not N.N"
if SUP=$(aws eks describe-cluster-versions --cluster-versions "$EKSVER" \
         --query 'clusterVersions[0].clusterVersion' --output text 2>/dev/null) && [[ "$SUP" == "$EKSVER" ]]; then
    pass "EKS supports version $EKSVER in $REGION"
else
    warn "could not confirm EKS supports version $EKSVER (describe-cluster-versions)"
fi

# ------------------------------------------------------------------ terraform outputs (optional)
section "Terraform outputs vs AWS"
if command -v terraform >/dev/null && [[ -d "$SETUP/.terraform" ]]; then
    OUT=$(cd "$SETUP" && terraform output -json 2>/dev/null || true)
    if [[ -n "$OUT" && "$OUT" != "{}" ]]; then
        check "output tfid = SSM id" "$ID" "$(echo "$OUT" | jq -r '.tfid.value')"
        check "output keyid = SSM keyid" "$KEYID" "$(echo "$OUT" | jq -r '.keyid.value')"
        check "output s3_bucket = SSM bucket-name" "$BUCKET" "$(echo "$OUT" | jq -r '.s3_bucket.value')"
        check "output region = SSM region" "$REGION" "$(echo "$OUT" | jq -r '.region.value')"
        rc=0; (cd "$SETUP" && terraform plan -input=false -no-color -detailed-exitcode -lock=false >/tmp/tf-setup-plan.log 2>&1) || rc=$?
        case $rc in
            0) pass "terraform plan: no drift" ;;
            2) fail "terraform plan shows changes (see /tmp/tf-setup-plan.log)" ;;
            *) warn "terraform plan failed (see /tmp/tf-setup-plan.log)" ;;
        esac
    else
        warn "tf-setup state has no outputs (state empty or not in this directory) - skipped"
    fi
else
    info "terraform not initialised in tf-setup - skipped"
fi

# ------------------------------------------------------------------ KMS key
section "KMS key $KEYID"
if KEY=$(aws kms describe-key --key-id "$KEYID" --output json 2>/dev/null); then
    check "key state" "Enabled" "$(echo "$KEY" | jq -r '.KeyMetadata.KeyState')"
    check "key ARN = SSM keyarn" "$KEYARN" "$(echo "$KEY" | jq -r '.KeyMetadata.Arn')"
    check "key usage" "ENCRYPT_DECRYPT" "$(echo "$KEY" | jq -r '.KeyMetadata.KeyUsage')"
    check "key description" "EKS KMS Key 2 $CLUSTER" "$(echo "$KEY" | jq -r '.KeyMetadata.Description')"
    check "key rotation enabled" "True" "$(aws kms get-key-rotation-status --key-id "$KEYID" --query KeyRotationEnabled --output text 2>/dev/null)"
else
    fail "KMS key $KEYID not found"
fi

# ------------------------------------------------------------------ S3 state bucket
section "S3 state bucket $BUCKET"
if aws s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
    pass "bucket exists and is accessible"
    LOC=$(aws s3api get-bucket-location --bucket "$BUCKET" --query LocationConstraint --output text)
    [[ "$LOC" == "None" || "$LOC" == "null" ]] && LOC="us-east-1"
    check "bucket region" "$REGION" "$LOC"
    ENC=$(aws s3api get-bucket-encryption --bucket "$BUCKET" --output json 2>/dev/null \
          | jq '.ServerSideEncryptionConfiguration.Rules[0]')
    check "default encryption" "aws:kms" "$(echo "$ENC" | jq -r '.ApplyServerSideEncryptionByDefault.SSEAlgorithm')"
    KMSID=$(echo "$ENC" | jq -r '.ApplyServerSideEncryptionByDefault.KMSMasterKeyID')
    [[ "$KMSID" == "$KEYID" || "$KMSID" == "$KEYARN" ]] && pass "encryption uses the workshop key" \
        || fail "encryption key is '$KMSID', expected $KEYID"
    check "bucket key enabled" "false" "$(echo "$ENC" | jq -r '.BucketKeyEnabled // false')"
    check "versioning" "Enabled" "$(aws s3api get-bucket-versioning --bucket "$BUCKET" --query Status --output text)"
    PAB=$(aws s3api get-public-access-block --bucket "$BUCKET" --output json 2>/dev/null | jq -c '.PublicAccessBlockConfiguration')
    for k in BlockPublicAcls IgnorePublicAcls BlockPublicPolicy RestrictPublicBuckets; do
        check "public access block $k" "true" "$(echo "$PAB" | jq -r ".$k")"
    done
    # State files written by later stages must be KMS encrypted with the workshop key
    OBJS=$(aws s3api list-objects-v2 --bucket "$BUCKET" --prefix terraform/ --query 'Contents[].Key' --output text 2>/dev/null)
    if [[ -z "$OBJS" || "$OBJS" == "None" ]]; then
        info "no stage state files in s3://$BUCKET/terraform/ yet"
    else
        for o in $OBJS; do
            [[ "$o" == *.tfstate ]] || continue
            H=$(aws s3api head-object --bucket "$BUCKET" --key "$o" --output json 2>/dev/null)
            sse=$(echo "$H" | jq -r '.ServerSideEncryption'); kid=$(echo "$H" | jq -r '.SSEKMSKeyId')
            [[ "$sse" == "aws:kms" && "$kid" == *"$KEYID" ]] && pass "$o encrypted with workshop key" \
                || fail "$o encryption is $sse / $kid"
        done
    fi
else
    fail "bucket $BUCKET not found or not accessible"
fi

# ------------------------------------------------------------------ gen-backend.sh output
section "Generated backend files (gen-backend.sh)"
if [[ -f "$SETUP/tmp-buck.txt" ]]; then
    check "tmp-buck.txt" "$BUCKET" "$(tr -d '[:space:]' < "$SETUP/tmp-buck.txt")"
else
    fail "tf-setup/tmp-buck.txt missing"
fi
for s in $SECTIONS; do
    f="$SETUP/generated/backend-$s.tf"
    if [[ ! -f "$f" ]]; then fail "generated/backend-$s.tf missing"; continue; fi
    b=$(sed -n 's/^ *bucket *= *"\(.*\)"/\1/p' "$f"); k=$(sed -n 's/^ *key *= *"\(.*\)"/\1/p' "$f")
    r=$(sed -n 's/^ *region *= *"\(.*\)"/\1/p' "$f" | head -1)
    if [[ "$b" == "$BUCKET" && "$k" == "terraform/$s.tfstate" && "$r" == "$REGION" ]] \
       && grep -q 'use_lockfile *= *true' "$f" && grep -q 'encrypt *= *true' "$f"; then
        pass "backend-$s.tf (bucket, key, region, lockfile, encrypt)"
    else
        fail "backend-$s.tf: bucket=$b key=$k region=$r (expected $BUCKET terraform/$s.tfstate $REGION, use_lockfile/encrypt true)"
    fi
    # Every stage except tf-setup consumes its backend file through a symlink
    if [[ "$s" != "tf-setup" ]]; then
        l="$ROOT/$s/backend-$s.tf"
        if [[ -L "$l" && "$(cd "$ROOT/$s" && cd "$(dirname "$(readlink "$l")")" && pwd)/backend-$s.tf" == "$f" ]]; then
            pass "$s/backend-$s.tf links to the generated file"
        else
            fail "$s/backend-$s.tf is missing or not a symlink to tf-setup/generated/backend-$s.tf"
        fi
    fi
done
if command -v terraform >/dev/null; then
    terraform fmt -check -recursive "$SETUP/generated" >/dev/null 2>&1 && pass "generated files are terraform fmt clean" \
        || warn "generated files are not terraform fmt clean"
fi
[[ -d "$HOME/.terraform.d/plugin-cache" ]] && pass "terraform plugin cache dir exists" \
    || warn "$HOME/.terraform.d/plugin-cache missing (gen-backend.sh creates it)"

# ------------------------------------------------------------------ EKS cluster (only if built)
section "EKS cluster $CLUSTER (consumer of cluster-name / eks-version)"
if C=$(aws eks describe-cluster --name "$CLUSTER" --output json 2>/dev/null); then
    check "cluster status" "ACTIVE" "$(echo "$C" | jq -r '.cluster.status')"
    check "cluster version = eks-version parameter" "$EKSVER" "$(echo "$C" | jq -r '.cluster.version')"
    if command -v kubectl >/dev/null; then
        SV=$(kubectl version -o json --request-timeout=15s 2>/dev/null | jq -r '.serverVersion | "\(.major).\(.minor)"' | tr -d '+')
        if [[ -n "$SV" && "$SV" != "null.null" ]]; then
            check "kubectl server version" "$EKSVER" "$SV"
            CTX=$(kubectl config current-context 2>/dev/null)
            [[ "$CTX" == *"$CLUSTER"* ]] && pass "kubectl context points at $CLUSTER ($CTX)" \
                || warn "kubectl context '$CTX' does not mention $CLUSTER"
        else
            warn "kubectl cannot reach the cluster API (private endpoint? run from the IDE instance)"
        fi
    fi
else
    info "cluster not created yet - skipped"
fi

# ------------------------------------------------------------------ summary
echo
echo "== Summary: $PASS passed, $FAIL failed, $WARN warnings"
[[ $FAIL -eq 0 ]]
