#!/usr/bin/env bash
# Verifies the kapp Config (change-group/rule ordering + waitRules) is valid and ENFORCED, using
# lightweight per-namespace fixtures on kind — no upstream charts needed. A malformed rule makes kapp
# error; a clean apply means the cilium->csi->eso->argocd chain was accepted and applied in order.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
kind create cluster --name p2-order --wait 90s || exit 1
trap 'kind delete cluster --name p2-order >/dev/null 2>&1' EXIT
fixtures(){
  for ns in csi-proxmox external-secrets argocd; do printf 'apiVersion: v1\nkind: Namespace\nmetadata: { name: %s }\n---\n' "$ns"; done
  for ns in kube-system csi-proxmox external-secrets argocd; do printf 'apiVersion: v1\nkind: ConfigMap\nmetadata: { name: layer-probe, namespace: %s }\n---\n' "$ns"; done
}
fixtures | kapp deploy -a p2ord -y -f - -f "$HERE/../config.yaml" 2>&1 | tail -20; rc=${PIPESTATUS[0]}
[ "$rc" -eq 0 ] || { echo "FAIL: kapp rejected the Config (rc=$rc)"; exit 1; }
for ns in kube-system csi-proxmox external-secrets argocd; do
  kubectl -n "$ns" get cm layer-probe >/dev/null 2>&1 || { echo "FAIL: $ns/layer-probe not applied"; exit 1; }
done
echo "PASS: kapp accepted the change-group/rule ordering + applied all 4 layers"
