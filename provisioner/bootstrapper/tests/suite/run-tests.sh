#!/usr/bin/env bash
# Runs every probes/*.sh; PASS/FAIL per probe; exits non-zero if ANY fails. (P3 phase 6 consumes this.)
set -uo pipefail
DIR="${1:?usage: run-tests.sh <probes-dir>}"; fail=0
for p in "$DIR"/*.sh; do [ -e "$p" ] || continue
  if "$p"; then echo "PASS $(basename "$p")"; else echo "FAIL $(basename "$p")"; fail=1; fi
done
exit $fail
