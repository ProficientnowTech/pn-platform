# P4 acceptance — the suite gates P3's self-destruct

After P3 phases 0–5 on the target cluster, `tests/suite/run-tests.sh tests/suite/probes` must exit 0
before the bootstrapper self-destructs (P3 phase 7). Per-probe expected on-cluster result:
- `10-cilium-l2` — ingress VIP answers (HTTP status, not timeout)
- `20-csi-pvc` — a 1Gi PVC binds on `proxmox-zfs-r1`
- `30-eso-secret` — a canary ExternalSecret materialises from the in-cluster Vault
- `40-eso-on-incluster-vault` — ESO `ClusterSecretStore.server` = `*.vault.svc` (NOT azurekv/ephemeral)
- `41-no-azure-dependency` — no live object references `vault.azure.net`/`azurekv`
- `42-ephemeral-gone` — the `bootstrap` namespace is absent
- `50-argocd-synced` — root + all apps `Synced`+`Healthy`
- `60-canary-workload` — a factory-deployed canary is `Running` (PV + ingress)
- `70-factory-validation` — a bad app entry is rejected at render (P1 gate live)

**Gated on the on-prem-primary milestone.**
