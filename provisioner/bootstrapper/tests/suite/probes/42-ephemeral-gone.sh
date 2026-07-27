#!/usr/bin/env bash
set -uo pipefail
kubectl get ns bootstrap >/dev/null 2>&1 && { echo "ephemeral: bootstrap ns still present"; exit 1; } || { echo "ephemeral: gone"; exit 0; }
