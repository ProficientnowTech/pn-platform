#!/usr/bin/env bash
# Pulls the 3 upstream foundation charts into .charts/ at the pinned versions the live cluster uses.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; CH="$HERE/.charts"; mkdir -p "$CH"
helm repo add cilium https://helm.cilium.io >/dev/null 2>&1 || true
helm repo add external-secrets https://charts.external-secrets.io >/dev/null 2>&1 || true
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update >/dev/null
helm pull cilium/cilium --version 1.17.17 --untar --untardir "$CH"
helm pull external-secrets/external-secrets --version 0.20.4 --untar --untardir "$CH"
helm pull argo/argo-cd --untar --untardir "$CH"
echo "vendored: $(ls "$CH")"
