# P3 orchestrator phase 6 — runs the P4 test suite; its exit code is the go/no-go for phase 7.
phase_6_tests(){
  local H; H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  "$H/../../tests/suite/run-tests.sh" "$H/../../tests/suite/probes"
}
