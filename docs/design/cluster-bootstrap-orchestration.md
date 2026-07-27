<!--
id:             DESIGN-PNPLATFORM-BOOTSTRAP-ORCH-2026-07-27
status:         approved-orchestration + azure-bootstrapper (pending implementation plan)
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
  `CNI(Cilium) → CSI(Proxmox) → secrets(ESO + AKV ClusterSecretStore) → Vault → ArgoCD`. ~6–10 things.
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
order barely matters post-bootstrap); the hard ordering was already done by kapp in Phase 1.

## 6. The ephemeral bootstrapper — provider-local vehicle, uniform lifecycle contract

The one-shot orchestrator that runs Phases 1–2 and then removes itself. **The *vehicle* is
provider-specific (it must reach the target cluster's API on a local path); the *lifecycle contract*
is uniform.**

### Vehicle (where it runs)
- **onprem / ovh (Proxmox):** an **ephemeral LXC or minimal VM ON the PVE cluster** — the RIGHT
  primary, not a fallback. An Azure-hosted runner would have to tunnel into the on-prem cluster API
  behind Sophos/the private net (a real reachability hassle); a Proxmox-local runner has direct
  local access. It reaches the AKV secret anchor via the **PVE host's Azure Arc managed identity**
  (the hosts are Arc-connected) → **no planted static credential.**
- **contabo / azure (cloud):** a cloud-local container — **Azure Container Instance** for `azure-dr`
  (co-located with AKV via workload identity); a Contabo-local container for `contabo-standby`.
- Either way the image bakes the toolchain: `kapp`, `terraform`/`bpg`, `talhelper`, `talosctl`,
  `argocd`/`kubectl`.

### Boundary contract (uniform across vehicles — the crisp when / what / when)
- **PROVISIONED — when:** the **substrate is DONE and verified** — PVE cluster (corosync/HA), host
  networking + VLANs, switch config, storage (ZFS+CSI), hardening — all Ansible/GitOps. The **final
  substrate step** provisions it. It lives exactly at the seam **substrate-ready → cluster-bootstrap.**
- **OWNS / DOES — only the transient bootstrap:** Talos VMs (bpg + Image Factory + talhelper) →
  `talosctl bootstrap` → kapp Phase-1 foundation (CNI→CSI→ESO/AKV→Vault→ArgoCD, converge-gated) →
  Phase-2 hand-off to ArgoCD + factory → the **test suites**. It does **NOT** own the substrate (done
  before it, by Ansible) or steady-state (ArgoCD, after it).
- **DEPROVISIONED — when:** the cluster is **self-managing (ArgoCD Synced + Healthy) AND the test
  suites pass** → it tears itself down (delete the LXC/VM/container, revoke transient access).
  **On FAILURE it persists** (scaffolding + logs for diagnosis; resumable with `--resume`).

Clean seams: **Ansible owns *before* · the ephemeral bootstrapper owns *during* · ArgoCD owns *after*.**

### Why ephemeral (both vehicles)
- **Self-destruct** = the elevated bootstrap privileges don't linger (security) and there's no standing
  scaffolding to operate (maintainability).
- **Test-gated** = the cluster is proven workload-ready before success is declared and the runner leaves.
- **Reproducible** = the process is one artifact; anyone can trigger a clean bootstrap.
- **Arc identity (Proxmox) / workload identity (cloud)** = the AKV anchor is reached without secret sprawl.
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
- The full **`app-factory` label taxonomy** — the next deliverable to draft (referenced in §3/§5).
- Steady-state day-2 (ArgoCD-owned, not this runner).
- Exact test-suite contents + the ACI-vs-Container-Apps-job final call — resolved in the implementation plan.
