#!/usr/bin/env bash
set -uo pipefail
srv=$(kubectl get clustersecretstore vault-backend -o jsonpath='{.spec.provider.vault.server}' 2>/dev/null)
case "$srv" in
  *.vault.svc*|*vault.vault*) echo "sovereign: ESO -> in-cluster Vault ($srv)"; exit 0 ;;
  *) echo "NOT sovereign: ESO server=$srv"; exit 1 ;;
esac
