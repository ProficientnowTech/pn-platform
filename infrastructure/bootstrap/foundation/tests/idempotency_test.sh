#!/usr/bin/env bash
# Foundation converges on kind (CSI stubbed), and a 2nd apply is a no-op (kapp --apply-exit-status=2).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
kind create cluster --name p2-idem --wait 120s
trap 'kind delete cluster --name p2-idem >/dev/null 2>&1' EXIT
export EPHEMERAL_VAULT_ADDR=http://x:8200 STUB=1
"$HERE/../deploy.sh" example || true
"$HERE/../deploy.sh" example; rc=$?
[ "$rc" -eq 2 ] && echo "PASS: re-apply is a no-op (exit 2)" || { echo "FAIL: rc=$rc (expected 2)"; exit 1; }
