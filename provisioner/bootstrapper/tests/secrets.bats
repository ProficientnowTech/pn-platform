setup() {
  O="$(cd "$BATS_TEST_DIRNAME/../orchestrator" && pwd)"
  source "$O/phases/01-secrets.sh"; source "$O/phases/05-handoff.sh"; source "$O/phases/07-cleanup.sh"
  vault server -dev -dev-root-token-id=root -dev-listen-address=127.0.0.1:8200 >/dev/null 2>&1 & VPID=$!
  vault server -dev -dev-root-token-id=root -dev-listen-address=127.0.0.1:8201 >/dev/null 2>&1 & VPID2=$!
  sleep 2; export VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root
}
teardown() { kill "$VPID" "$VPID2" 2>/dev/null || true; }

@test "phase_1_secrets requires the age key" {
  export SECRETS_DIR="$BATS_TEST_TMPDIR/s"; mkdir -p "$SECRETS_DIR"; unset SOPS_AGE_KEY_FILE
  run phase_1_secrets; [ "$status" -ne 0 ]; [[ "$output" == *"age key required"* ]]
}
@test "phase_1_secrets seeds Vault from a SOPS fixture" {
  export SECRETS_DIR="$BATS_TEST_TMPDIR/s"; mkdir -p "$SECRETS_DIR"
  age-keygen -o "$BATS_TEST_TMPDIR/age.key" 2>/dev/null
  pub="$(age-keygen -y "$BATS_TEST_TMPDIR/age.key")"
  printf 'csitoken: test-token\n' > "$BATS_TEST_TMPDIR/p.yaml"
  sops --encrypt --age "$pub" "$BATS_TEST_TMPDIR/p.yaml" > "$SECRETS_DIR/proxmox-cloud-config.sops.yaml"
  export SOPS_AGE_KEY_FILE="$BATS_TEST_TMPDIR/age.key"
  run phase_1_secrets; [ "$status" -eq 0 ]
  run vault kv get -field=csitoken secret/proxmox-cloud-config; [ "$output" = "test-token" ]
}
@test "migrate copies all secret paths ephemeral->in-cluster; repoint flips ESO server" {
  vault kv put secret/proxmox-cloud-config csitoken=abc >/dev/null
  migrate_secrets "http://127.0.0.1:8200" "http://127.0.0.1:8201"
  run env VAULT_ADDR=http://127.0.0.1:8201 vault kv get -field=csitoken secret/proxmox-cloud-config
  [ "$output" = "abc" ]
  printf 'spec:\n  provider:\n    vault:\n      server: http://ephemeral-vault.bootstrap.svc:8200\n' > "$BATS_TEST_TMPDIR/store.yaml"
  repoint_eso "$BATS_TEST_TMPDIR/store.yaml" "http://vault.vault.svc:8200"
  run yq '.spec.provider.vault.server' "$BATS_TEST_TMPDIR/store.yaml"; [ "$output" = "http://vault.vault.svc:8200" ]
}
@test "cleanup destroys on pass, persists on fail" {
  export DESTROY_CMD="touch $BATS_TEST_TMPDIR/destroyed"; export SOPS_AGE_KEY_FILE=""
  run phase_7_cleanup_impl pass; [ "$status" -eq 0 ]; [ -f "$BATS_TEST_TMPDIR/destroyed" ]
  rm -f "$BATS_TEST_TMPDIR/destroyed"
  run phase_7_cleanup_impl fail; [ "$status" -ne 0 ]; [ ! -f "$BATS_TEST_TMPDIR/destroyed" ]
}
