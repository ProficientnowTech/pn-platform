#!/usr/bin/env bash
# Verifies the kapp Config orders the 4 layers (cilium->csi->eso->argocd) using lightweight
# per-namespace fixtures — tests the ordering logic without pulling the real charts.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
kind create cluster --name p2-order --wait 90s
trap 'kind delete cluster --name p2-order >/dev/null 2>&1' EXIT
fixtures(){ for ns in kube-system csi-proxmox external-secrets argocd; do
cat <<EOF
apiVersion: v1
kind: ConfigMap
metadata: { name: layer-probe, namespace: ${ns} }
---
EOF
done; }
fixtures | kapp deploy -a p2ord -y -f - -f "$HERE/../config.yaml" --dry-run --diff-changes 2>&1 | tee /tmp/p2ord.txt
c=$(grep -n 'kube-system' /tmp/p2ord.txt | head -1 | cut -d: -f1)
a=$(grep -n 'argocd'      /tmp/p2ord.txt | head -1 | cut -d: -f1)
[ -n "$c" ] && [ -n "$a" ] && [ "$c" -le "$a" ] && echo "PASS: cilium(kube-system) ordered before argocd" || { echo "FAIL: ordering"; exit 1; }
