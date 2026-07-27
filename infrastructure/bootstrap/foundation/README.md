# infrastructure/bootstrap/foundation — the kapp Phase-1 foundation (P2)

One idempotent, converge-gated `kapp deploy` brings a bare Talos cluster to
**Cilium → Proxmox-CSI(+CCM) → ESO → ArgoCD**, secrets from the ephemeral Vault (P3). Vault is NOT here.

- `render.sh <cluster>` — helm-templates the 4 layers (+ `extra/` manifests, envsubst'd) | kbld.
- `deploy.sh <cluster>` — `render | kapp deploy` with `config.yaml` (ordering + wait-rules) + `--apply-exit-status`.
- `config.yaml` — kapp `changeGroupBindings`/`changeRuleBindings` (order by namespace) + `waitRules`
  (gate on ESO `ClusterSecretStore`/`ExternalSecret` `Ready`, so ordering waits on REAL convergence).
- `vendor-charts.sh` — pulls the 3 upstream charts (cilium/external-secrets/argo-cd) into `.charts/`
  (gitignored). Cilium values + proxmox-csi charts are vendored from ovh-infra `onprem/platform-live`.
- `30-external-secrets/extra/` — the **`vault-backend`** ClusterSecretStore (→ ephemeral Vault, NOT azure-kv)
  + the foundation ExternalSecrets (csi token, argocd github-app, cloudflare).
- `clusters/<cluster>.env` — per-cluster inputs (`example.env` is the CI fixture; real from the registry).

Tests: `tests/ordering_test.sh` (kapp `--dry-run` layer order on kind), `tests/idempotency_test.sh`
(converge + no-op re-apply on kind, CSI stubbed), `tests/acceptance.md` (real-cluster gate).
