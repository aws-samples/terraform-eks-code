#!/usr/bin/env bash
# Build one or more stages. Kept for compatibility: the logic now lives in build-all.sh.
# Usage: ./build-stage.sh <stage> [stage ...]
set -euo pipefail
[[ $# -gt 0 ]] || { echo "usage: $0 <stage> [stage ...]"; exit 1; }
exec "$(dirname "${BASH_SOURCE[0]}")/build-all.sh" "$@"
