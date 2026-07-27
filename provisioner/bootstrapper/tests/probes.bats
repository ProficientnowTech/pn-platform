setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
  SUITE="$REPO/provisioner/bootstrapper/tests/suite"
  MOCKBIN="$BATS_TEST_TMPDIR/bin"; mkdir -p "$MOCKBIN"
  cat > "$MOCKBIN/kubectl" <<'EOM'
#!/usr/bin/env bash
a=" $* "
[[ "$a" == *" apply "* || "$a" == *" delete "* ]] && exit 0
if [[ "$a" == *" get "* ]]; then
  [[ "$a" == *clustersecretstore* ]] && { echo "${MOCK_VAULT_SERVER:-}"; exit 0; }
  [[ "$a" == *pvc* ]] && { echo "${MOCK_PHASE:-}"; exit 0; }
  echo ""; exit 0
fi
exit 0
EOM
  printf '#!/usr/bin/env bash\necho "${MOCK_HTTP_CODE:-200}"\n' > "$MOCKBIN/curl"
  chmod +x "$MOCKBIN"/*
  PATH="$MOCKBIN:$PATH"
}

@test "harness: fails if any probe fails, passes if all pass" {
  d="$BATS_TEST_TMPDIR/p"; mkdir -p "$d"
  printf '#!/bin/sh\nexit 0\n' > "$d/a.sh"; printf '#!/bin/sh\nexit 1\n' > "$d/b.sh"; chmod +x "$d"/*.sh
  run "$SUITE/run-tests.sh" "$d"; [ "$status" -ne 0 ]; [[ "$output" == *"FAIL b.sh"* ]]
  rm "$d/b.sh"
  run "$SUITE/run-tests.sh" "$d"; [ "$status" -eq 0 ]
}
@test "csi-pvc probe: Bound passes, Pending fails" {
  export MOCK_PHASE=Bound;   run "$SUITE/probes/20-csi-pvc.sh"; [ "$status" -eq 0 ]
  export MOCK_PHASE=Pending; run "$SUITE/probes/20-csi-pvc.sh"; [ "$status" -ne 0 ]
}
@test "sovereignty probe: in-cluster Vault passes, AKV/azure fails" {
  export MOCK_VAULT_SERVER=http://vault.vault.svc:8200; run "$SUITE/probes/40-eso-on-incluster-vault.sh"; [ "$status" -eq 0 ]
  export MOCK_VAULT_SERVER=https://kv.vault.azure.net;   run "$SUITE/probes/40-eso-on-incluster-vault.sh"; [ "$status" -ne 0 ]
}
@test "cilium-l2 probe: HTTP response passes, no-response fails" {
  export MOCK_HTTP_CODE=404; run "$SUITE/probes/10-cilium-l2.sh"; [ "$status" -eq 0 ]
  export MOCK_HTTP_CODE=000; run "$SUITE/probes/10-cilium-l2.sh"; [ "$status" -ne 0 ]
}
@test "factory-validation probe: bad tier rejected (P1 render-gate is live)" {
  export AF_DIR="$REPO/platform/app-factory"; run "$SUITE/probes/70-factory-validation.sh"
  [ "$status" -eq 0 ]; [[ "$output" == *"correctly rejected"* ]]
}
