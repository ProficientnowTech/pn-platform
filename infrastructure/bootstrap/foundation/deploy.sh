#!/usr/bin/env bash
# One-shot, idempotent, converge-gated foundation apply.
set -euo pipefail
CLUSTER="${1:?usage: deploy.sh <cluster>}"; HERE="$(cd "$(dirname "$0")" && pwd)"
"$HERE/render.sh" "$CLUSTER" | kapp deploy -y -a foundation -f - -f "$HERE/config.yaml" \
  --wait-timeout=20m --wait-resource-timeout=10m --apply-exit-status
