#!/usr/bin/env bash
#
# Run the stage validation tests in build order and print a one-line result per stage.
#
# Usage:
#   ./run-stage-tests.sh                 # all stages
#   ./run-stage-tests.sh net cluster     # only the named stages
#
# Output of each test goes to .aws-staff/tests/logs/<stage>.log. Exit code is non-zero if any stage failed.
#
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALL="tf-setup net cluster nodepool addons sampleapp observ istio"
script_for() {
    case "$1" in
        tf-setup) echo test00-tf-setup.sh ;;  net) echo test10-net.sh ;;
        cluster) echo test20-cluster.sh ;;    nodepool) echo test30-nodepool.sh ;;
        addons) echo test40-addons.sh ;;      sampleapp) echo test50-sampleapp.sh ;;
        observ) echo test60-observ.sh ;;      istio) echo test70-istio.sh ;;
        *) return 1 ;;
    esac
}
STAGES="${*:-$ALL}"
for s in $STAGES; do script_for "$s" >/dev/null || { echo "unknown stage '$s' (valid: $ALL)"; exit 2; }; done

mkdir -p "$DIR/logs"
rc=0
printf '%-10s %-6s %s\n' STAGE RESULT SUMMARY
for s in $STAGES; do
    log="$DIR/logs/$s.log"
    if "$DIR/$(script_for "$s")" >"$log" 2>&1; then r=PASS; else r=FAIL; rc=1; fi
    printf '%-10s %-6s %s\n' "$s" "$r" "$(grep '^== Summary' "$log" | tail -1 | sed 's/^== Summary: //')"
    [[ $r == FAIL ]] && grep '  FAIL  ' "$log" | head -5 | sed 's/^/             /'
done
echo "logs: $DIR/logs/"
exit $rc
