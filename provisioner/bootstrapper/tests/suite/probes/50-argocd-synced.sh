#!/usr/bin/env bash
set -uo pipefail
bad=$(kubectl get applications -n argocd -o jsonpath='{range .items[*]}{.status.sync.status}/{.status.health.status}{"\n"}{end}' 2>/dev/null | grep -vE '^Synced/Healthy$' | grep -v '^$' || true)
[ -z "$bad" ] && { echo "argocd: all Synced+Healthy"; exit 0; } || { echo "argocd: not-green -> $bad"; exit 1; }
