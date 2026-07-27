#!/usr/bin/env bash
set -uo pipefail
hits=$(kubectl get clustersecretstores,externalsecrets -A -o yaml 2>/dev/null | grep -iE 'vault\.azure\.net|azurekv' || true)
[ -z "$hits" ] && { echo "no-azure: clean"; exit 0; } || { echo "no-azure: AKV refs remain"; exit 1; }
