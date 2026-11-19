#!/usr/bin/env bash
# Build the stages up to and including cluster (see build-all.sh)
set -euo pipefail
exec "$(dirname "${BASH_SOURCE[0]}")/build-all.sh" tf-setup net cluster
