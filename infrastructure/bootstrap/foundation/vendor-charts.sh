#!/usr/bin/env bash
# Pulls the upstream foundation artifacts into .charts/ at the PINNED versions the live cluster uses.
#
# Everything here is pinned, deliberately: this stream is meant to be digest-pinned, so an unpinned
# fetch means identical git state produces a different cluster depending on the day it was vendored.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; CH="$HERE/.charts"; mkdir -p "$CH"

CILIUM_VERSION="1.17.17"
ESO_VERSION="0.20.4"
ARGOCD_VERSION="7.7.11"        # D2: was unpinned — see below
CERT_MANAGER_VERSION="v1.20.3" # D1: CRDs only; the controller arrives later via ArgoCD

helm repo add cilium https://helm.cilium.io >/dev/null 2>&1 || true
helm repo add external-secrets https://charts.external-secrets.io >/dev/null 2>&1 || true
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update >/dev/null

helm pull cilium/cilium --version "$CILIUM_VERSION" --untar --untardir "$CH"
helm pull external-secrets/external-secrets --version "$ESO_VERSION" --untar --untardir "$CH"

# D2 — argo-cd was pulled with NO --version while its two peers were pinned. Same git state, different
# ArgoCD by vendoring date, in a foundation whose whole premise is reproducibility. 7.7.11 is the version
# the live cluster runs and that ovh-infra's seed pins.
helm pull argo/argo-cd --version "$ARGOCD_VERSION" --untar --untardir "$CH"

# D1 — cert-manager CRDs. NOT optional and NOT cosmetic:
# 10-cilium/values.yaml sets hubble.tls.auto.method=certmanager, so the Cilium render emits
# cert-manager.io/v1 Certificate objects. Nothing else in this foundation provides those CRDs, and the
# cert-manager CONTROLLER only arrives later via ArgoCD — so without this, kapp applies an unknown kind
# and the CNI never installs. No CNI means no node ever reaches Ready, which means nothing else in the
# foundation can schedule either. `helm template` cannot catch this (it never contacts a cluster).
# Verified on real hardware: this is the same wall the interim cluster hit, fixed the same way — CRDs
# first, controller later. The Certificates simply sit Pending until the controller shows up; cilium-agent
# (the actual datapath) comes up immediately.
curl -fsSL -o "$CH/cert-manager.crds.yaml" \
  "https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.crds.yaml"

echo "vendored: $(ls "$CH")"
