# phase 5 — deploy in-cluster Vault (ArgoCD), MIGRATE secrets ephemeral->in-cluster, REPOINT ESO.
phase_5_handoff(){ echo "handoff: migrate + repoint (see migrate_secrets / repoint_eso)"; }
# migrate every secret/* path from src Vault ($1) to dst Vault ($2). Same VAULT_TOKEN for both.
migrate_secrets(){
  local p tmp
  for p in $(VAULT_ADDR="$1" vault kv list -format=json secret 2>/dev/null | jq -r '.[]'); do
    tmp="$(mktemp)"
    VAULT_ADDR="$1" vault kv get -format=json "secret/$p" | jq '.data.data' > "$tmp"
    VAULT_ADDR="$2" vault kv put "secret/$p" "@$tmp" >/dev/null
    rm -f "$tmp"
  done
}
# repoint the ESO ClusterSecretStore manifest ($1) to the new Vault server ($2).
repoint_eso(){ yq -i ".spec.provider.vault.server = \"$2\"" "$1"; }
