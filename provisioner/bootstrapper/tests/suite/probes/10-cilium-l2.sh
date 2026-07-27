#!/usr/bin/env bash
set -uo pipefail
VIP="${INGRESS_VIP:-192.168.103.100}"; HOST="${CANARY_HOST:-argocd.aps2.pnats.cloud}"
code=$(curl -m6 -s -o /dev/null -w '%{http_code}' "http://$VIP/" -H "Host: $HOST" 2>/dev/null || echo 000)
[ "$code" != "000" ] && { echo "cilium-l2: VIP answered ($code)"; exit 0; } || { echo "cilium-l2: no response"; exit 1; }
