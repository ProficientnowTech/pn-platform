# phase 1 — ephemeral Vault up + seed from SOPS (age key). Sole secret input = SOPS_AGE_KEY_FILE.
phase_1_secrets(){
  [ -f "${SOPS_AGE_KEY_FILE:-/nonexistent}" ] || { echo "age key required (SOPS_AGE_KEY_FILE)"; return 1; }
  : "${VAULT_ADDR:=http://127.0.0.1:8200}"; export VAULT_ADDR
  local f name tmp
  for f in "${SECRETS_DIR:-secrets}"/*.sops.yaml; do
    [ -e "$f" ] || continue
    name="$(basename "$f" .sops.yaml)"; tmp="$(mktemp)"
    sops -d "$f" | yq -o=json - > "$tmp"
    vault kv put "secret/$name" "@$tmp" >/dev/null
    rm -f "$tmp"
  done
  vault auth enable kubernetes >/dev/null 2>&1 || true
  echo "ephemeral Vault seeded"
}
