#!/usr/bin/env bash
set -uo pipefail
got=$(kubectl -n default get secret eso-probe -o jsonpath='{.data}' 2>/dev/null)
[ -n "$got" ] && { echo "eso-secret: materialised"; exit 0; } || { echo "eso-secret: not materialised"; exit 1; }
