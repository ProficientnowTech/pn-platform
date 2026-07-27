#!/usr/bin/env bash
# P3 orchestrator phase 6 — runs the P4 test suite; its exit code is the go/no-go for phase 7 (self-destruct).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec "$HERE/../../tests/suite/run-tests.sh" "$HERE/../../tests/suite/probes"
