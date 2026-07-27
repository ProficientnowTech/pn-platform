#!/usr/bin/env bash
# Proves P1's render-time validation is LIVE: a bad tier must FAIL the render.
set -uo pipefail
AF="${AF_DIR:?set AF_DIR to platform/app-factory}"
if helm template "$AF/tests-consumer" --set vApp.name=x --set vApp.domain=security \
     --set vApp.version=1.0.0 --set vApp.team=platform --set vApp.tier=BADTIER \
     --set vApp.dependency-layer=core >/dev/null 2>&1; then
  echo "factory-validation: bad tier NOT rejected"; exit 1
else
  echo "factory-validation: bad tier correctly rejected"; exit 0
fi
