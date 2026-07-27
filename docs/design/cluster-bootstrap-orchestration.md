<!--
id:             DESIGN-PNPLATFORM-BOOTSTRAP-ORCH-2026-07-27
status:         approved-orchestration + SOVEREIGN ephemeral bootstrapper (§10 supersedes the AKV-anchor model); feeds P2–P4
target_repo:    THIS repo (ProficientNowTech/pn-platform, branch main)
related:        docs/design/directory-structure-and-cluster-registry.md
                ovh-infra:docs/deployment-platform-design/appendices/A3-pn-infra-study.json (factory gaps analysis)
-->

# Design — Cluster bootstrap orchestration + the ephemeral Azure bootstrapper

## 1. Goal

Bring a cluster from bare foundation to **self-managing (ArgoCD-owned)** in one health-gated,
idempotent pass — and run that pass from an **ephemeral Azure-hosted orchestrator** that creates
everything the bootstrap needs, validates it with test suites, then **vanishes**, leaving only the
self-managing cluster.

## 2. The two-phase model (the balance)

The dependency-ordering problem is **transient — it exists only during bootstrap.** Once the cluster
is up, apps use a standardized factory chart and are mostly independent, so ordering "doesn't matter."
Two phases, and the whole design hinges on keeping them separate:

- **Phase 1 — FOUNDATION bootstrap (one-shot, converge-gated):** the small hard-ordered set —
  `CNI(Cilium) → CSI(Proxmox) → secrets(ESO) → ArgoCD`. ~5–8 things. **Vault is NOT in the foundation**
  (it is an ArgoCD-managed *platform* app, adopted after hand-off — §10); ESO reads its bootstrap secrets
  from an **ephemeral, in-bootstrapper secret service**, not Azure AKV (§10).
- **Phase 2 — HAND-OFF:** ArgoCD + the factory deploy the **100–200 apps**, ordered by a **flat
  dependency-LAYER label**, then reconcile forever. The bootstrapper is gone by now.

### Why neither extreme

- **All 200 through the bootstrap tool** — wrong: the tool becomes a monster, and it's imperative, not
  reconciled.
- **The old stack-orchestrator** — wrong: nested domain hierarchy (root → umbrella → target-chart →
  leaf), 11× template duplication, and the sync-wave race (A3 study). Also: ArgoCD has **no native
  cross-Application dependency graph** (argo-cd#4577/#7437, 4+ yrs open), and **per-app Lua health
  checks don't scale to 200** (bug-farm + maintenance sink).

## 3. The dependency-layer grouping (how the 100–200 apps order without a hierarchy)

Every app carries **two orthogonal labels** stamped by the `app-factory` chart:

- **AppProject** — RBAC / governance (who owns it).
- **dependency-layer** — ordering (what must be healthy before it).

**Ordering keys off the `dependency-layer` label, cluster-wide, orthogonal to AppProjects.** So a
layer-2 app in project `databases` naturally waits on a layer-1 app in project `security` — the
ordering spans AppProjects because it keys off the *layer*, not the project boundary. This is **flat
grouping-by-dependency, expressed as data — not a nested Application hierarchy.** Because most of the
200 apps are order-independent, the number of real layers stays small (a handful), so it never grows
into a hierarchy. Dependency edges live as **chart data in the factory chart**, not hand-authored Lua.

## 4. Phase 1 tool decision — `kapp` (Carvel)

**`kapp` the CLI** (not kapp-controller) drives the foundation bring-up:

- **`change-groups` + `change-rules` = flat grouping-by-dependency** — "apply the `csi` group only
  after the `cni` group converges." This is the exact grouping model above, no nesting.
- **Blocks on real object convergence** (`waitRules` for custom kinds) — the safest gate for the
  Cilium/Proxmox-CSI/ESO **CRDs** that race today (they'd otherwise be scored "healthy on create").
- **One-shot, disappears** — a CLI, nothing stays in-cluster after.

Runner-up: **Helmfile** (`needs:` + `wait: true`) — simpler + Helm-native, but `helm --wait` is a
weaker per-release gate than kapp's convergence. **Rejected: KubeVela** — a staying OAM controller,
against the "vanishes / low-maintenance" goal.

## 5. Phase 2 — hand-off to ArgoCD + the factory

kapp's last groups install **ArgoCD** and apply the **root**; from there ArgoCD owns everything. The
factory (`app-factory` library chart) stamps each Application with `{AppProject, dependency-layer}` +
the full label taxonomy. Layer ordering in steady state is intentionally *soft* (ArgoCD reconciles;
order barely matters post-bootstrap); the hard ordering was already done by kapp in Phase 1. ArgoCD then
brings up the **in-cluster Vault** (platform app); the bootstrapper migrates secrets into it and repoints
ESO before it self-destructs — the sovereignty lifecycle in §10.

## 6. The ephemeral bootstrapper — provider-local vehicle, uniform lifecycle contract

The one-shot orchestrator that runs Phases 1–2 and then removes itself. **The *vehicle* is
provider-specific (it must reach the target cluster's API on a local path); the *lifecycle contract*
is uniform.**

### Vehicle (where it runs)
- **onprem / ovh (Proxmox):** an **ephemeral LXC or minimal VM ON the PVE cluster** — the RIGHT
  primary, not a fallback. An Azure-hosted runner would have to tunnel into the on-prem cluster API
  behind Sophos/the private net (a real reachability hassle); a Proxmox-local runner has direct
  local access. It carries **no standing cloud credential**: bootstrap secrets come from the
  **ephemeral in-bootstrapper Vault** (SOPS + operator age key) — the AKV/Arc anchor is removed (§10).
- **contabo / azure (cloud):** a cloud-local container — **Azure Container Instance** for `azure-dr`
  (co-located with AKV via workload identity); a Contabo-local container for `contabo-standby`.
- Either way the image bakes the toolchain: `kapp`, `terraform`/`bpg`, `talhelper`, `talosctl`,
  `argocd`/`kubectl`.

### Boundary contract (uniform across vehicles — the crisp when / what / when)
- **PROVISIONED — when:** the **substrate is DONE and verified** — PVE cluster (corosync/HA), host
  networking + VLANs, switch config, storage (ZFS+CSI), hardening — all Ansible/GitOps. The **final
  substrate step** provisions it. It lives exactly at the seam **substrate-ready → cluster-bootstrap.**
- **OWNS / DOES — only the transient bootstrap:** the **3 ephemeral-local services** (secret / image /
  repo — §10.1) → Talos VMs (bpg + Image Factory + talhelper) → `talosctl bootstrap` → kapp Phase-1
  foundation (CNI→CSI→ESO→ArgoCD, converge-gated) → Phase-2 hand-off to ArgoCD + factory → **migrate
  secrets to the in-cluster Vault + repoint ESO** → the **test suites**. It does **NOT** own the substrate
  (done before it, by Ansible) or steady-state (ArgoCD, after it).
- **DEPROVISIONED — when:** the cluster is **self-managing (ArgoCD Synced + Healthy) AND the test
  suites pass** → it tears itself down (delete the LXC/VM/container, revoke transient access).
  **On FAILURE it persists** (scaffolding + logs for diagnosis; resumable with `--resume`).

Clean seams: **Ansible owns *before* · the ephemeral bootstrapper owns *during* · ArgoCD owns *after*.**

### Why ephemeral (both vehicles)
- **Self-destruct** = the elevated bootstrap privileges don't linger (security) and there's no standing
  scaffolding to operate (maintainability).
- **Test-gated** = the cluster is proven workload-ready before success is declared and the runner leaves.
- **Reproducible** = the process is one artifact; anyone can trigger a clean bootstrap.
- **Sovereign secrets** = seeded from SOPS + an operator age key into an ephemeral Vault, migrated to the
  in-cluster Vault, then destroyed — **no standing Azure dependency** on the primary (§10).
- **Idempotent + resumable + gated** — physical/manual steps are operator-confirmed gates *before* the
  substrate hand-off, so the ephemeral runner itself only ever does the automatable part.

## 7. Per-cluster applicability

- **on-prem-primary / ovh-proving-ground (Proxmox):** the **physical substrate** (PVE/switch/wiring) is
  operator-gated Ansible/GitOps, *before* the runner; the **Proxmox-local ephemeral LXC/VM** then drives
  Talos-VM provisioning → kapp foundation → ArgoCD → tests → self-destruct. (OVH is Proxmox → identical
  path from Talos up.)
- **contabo-standby / azure-dr:** a cloud-local container (ACI for azure) drives the substrate too
  (Terraform), end to end.

## 8. Relationship to the deferred `pn` CLI

The Azure ACI is the **runtime vehicle** for the (deferred) `pn infra bootstrap` logic — it *runs* the
orchestration; the CLI's internal engine (Step/Phase/Runner/State/Gate) remains in its own deferred
spec. Same guardrail: **owns no config** — reads the cluster registry + kapp groups + talconfig + TF
vars; it orchestrates, it never generates state.

## 9. Out of scope / next

- The `pn` CLI internals (deferred spec).
- The **`app-factory` label taxonomy** — DONE (`docs/design/app-factory-label-taxonomy.md` + `-values-schema.md`).
- Steady-state day-2 (ArgoCD-owned, not this runner).
- The implementation plans **P2** (kapp foundation), **P3** (sovereign ephemeral bootstrapper), **P4**
  (Phase-2 hand-off + tests) — realise §2–§10 against the live reference configs (§10.7).

## 10. Secret & dependency sovereignty — inputs, the ephemeral-local services, the migration lifecycle

**Principle (confirmed):** the cluster must not carry standing external (Azure/cloud) dependencies beyond
what is strictly necessary. **AKV is removed from the bootstrap path**; Azure remains only a DR anchor.

### 10.1 The three ephemeral-local services
In the bootstrapper, seeded from operator inputs, each **replaces** a would-be standing external dependency
and is **migrated** to its in-cluster self-managed equivalent before the bootstrapper self-destructs:

| Ephemeral service (in bootstrapper) | Replaces | Migrates to (steady-state) |
|---|---|---|
| **Ephemeral Vault** | Azure Key Vault | in-cluster **Vault** (platform app); ESO repointed to `vault-backend` |
| **Local image cache/registry** | public registries (quay/ghcr/docker) + `factory.talos.dev` | in-cluster **Harbor** pull-through |
| **Local repo checkout** (kapp reads it) | GitHub during the foundation apply | ArgoCD → GitHub (SoT; self-hosted git later) |

### 10.2 The secret lifecycle (4 phases)
1. **Bootstrap (Azure-free):** the ephemeral Vault, seeded from SOPS-encrypted repo secrets (age key =
   operator input), backs ESO's bootstrap `ClusterSecretStore`. Foundation secrets flow locally.
2. **Foundation:** kapp brings up Cilium→CSI→ESO→ArgoCD using those secrets.
3. **Hand-off:** ArgoCD deploys the in-cluster Vault; the bootstrapper **migrates** secrets ephemeral→in-
   cluster Vault and **repoints** ESO's `ClusterSecretStore` from the ephemeral source to `vault-backend`.
4. **Cleanup (after tests pass):** ephemeral Vault + age key + bootstrapper self-destruct → fully sovereign
   (in-cluster Vault, ESO→Vault, zero standing Azure).

### 10.3 Bootstrap inputs (operator, at trigger — the minimal human set)
- **SOPS/age private key** — decrypts `talsecret.sops.yaml` + all `*.sops.yaml`. The one secret input.
- **Target cluster** — `onprem-primary | ovh-proving-ground` → selects `nodes.yaml` + `talconfig` + registry.
- **Repo checkout** — mounted into the bootstrapper (no standing git creds; ArgoCD gets its GitHub-App creds
  from the in-cluster Vault post-hand-off).
- (**PVE API token** is SOPS-encrypted in-repo → covered by the age key, not a second input.)

### 10.4 Substrate prerequisites (before the bootstrapper — Ansible/ops)
PVE cluster (corosync/HA) + pool `k8s` + ZFS `local-zfs`; VLANs 100/116 + Sophos egress + ingress VIP; PVE
API reachable; **external DNS + NTP** (Talos PKI needs correct clocks); bootstrapper reachability to PVE API
`:8006`, Talos API `:50000`, k8s `:6443`.

### 10.5 Bootstrap secrets (verified from `onprem/platform-live` — seeded into the ephemeral Vault)
- `talsecret.sops.yaml` — Talos PKI root (cluster CA + bootstrap token)
- `pve-csi-token-secret` — Proxmox CSI/CCM
- `onprem-argocd-github-{app-id, installation-id, privatekey}` — ArgoCD repo pull
- `cloudflare-api-token` — cert-manager + external-dns (platform-layer; the `:443` cert path)

### 10.6 Generated outputs (captured sovereignly — NOT to AKV)
`talosconfig` + `kubeconfig`; the in-cluster Vault **init recovery keys + root token** (sealed in-cluster +
an operator copy). The in-cluster Vault unseal method is a platform-app decision — sovereign (Shamir/Transit),
never AKV.

### 10.7 Live reference configs (P2–P4 reuse verbatim — ovh-infra `onprem/platform-live`)
`infrastructure/talos/`: `talconfig.yaml`, `nodes.yaml`, `image-factory/`, and `platform/` (Cilium values +
`cilium-lb` L2, `proxmox-csi` + CCM, `external-secrets` + the `azure-kv` store [→ superseded by the ephemeral
Vault/in-cluster Vault], `argocd` + `apps/root.yaml`). Terraform `modules/proxmox-talos-vm` +
`environments/onprem-k8s`. The manual helm/kubectl bring-up these encode is exactly what **P2** replaces with
the kapp one-shot.
