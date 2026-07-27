#!/usr/bin/env bash
# Renders the 4 foundation layers (helm template) into one digest-pinned YAML stream for kapp.
set -euo pipefail
CLUSTER="${1:?usage: render.sh <cluster>}"
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/clusters/$CLUSTER.env"
export EPHEMERAL_VAULT_ADDR PVE_API_URL PVE_REGION
CH="$HERE/.charts"   # upstream charts land here via vendor-charts.sh (cilium, external-secrets, argo-cd)
r(){ helm template "$1" "$2" -n "$3" -f "$4" --include-crds; }
{
  r cilium            "$CH/cilium"                                  kube-system      "$HERE/10-cilium/values.yaml"
  r proxmox-csi       "$HERE/20-proxmox-csi/proxmox-csi-plugin"     csi-proxmox      "$HERE/20-proxmox-csi/proxmox-csi-plugin/values.talos.yaml"
  r proxmox-ccm       "$HERE/20-proxmox-csi/proxmox-cloud-controller-manager" csi-proxmox "$HERE/20-proxmox-csi/proxmox-cloud-controller-manager/values.talos.yaml"
  r external-secrets  "$CH/external-secrets"                        external-secrets "$HERE/30-external-secrets/values.yaml"
  r argocd            "$CH/argo-cd"                                 argocd           "$HERE/40-argocd/values.yaml"
  for x in "$HERE"/*/extra/*.yaml; do [ -e "$x" ] && envsubst < "$x"; done
} | { command -v kbld >/dev/null 2>&1 && kbld -f - || cat; }
