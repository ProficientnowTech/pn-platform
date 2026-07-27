#!/usr/bin/env bash
set -uo pipefail
st=$(kubectl -n default get pod canary -o jsonpath='{.status.phase}' 2>/dev/null)
[ "$st" = Running ] && { echo "workload: canary Running"; exit 0; } || { echo "workload: canary ${st:-absent}"; exit 1; }
