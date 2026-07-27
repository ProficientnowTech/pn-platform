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

## 6. The ephemeral Azure bootstrapper

The one-shot orchestrator that runs Phases 1–2 and then removes itself.

- **Vehicle: Azure Container Instance (ACI)** — an ephemeral container (preferred over a VM: no OS to
  manage, seconds to start, pay-per-second, trivial teardown). Image bakes the toolchain
  (`kapp`, `terraform`/`bpg`, `ansible`, `talhelper`, `talosctl`, `argocd`/`kubectl`, the bootstrap logic).
- **Identity: an Azure managed identity / bootstrap SP** with exactly: AKV read (the secret **anchor**),
  target-cluster access (kubeconfig/talosconfig, from AKV), and permission to **create + destroy its own
  ephemeral resources**. Nothing broader; time-boxed.
- **Lifecycle (one-shot, self-destructing):**
  1. **CREATE** — Terraform (`azurerm`) provisions an ephemeral resource group + ACI + identity + role
     assignments.
  2. **BOOTSTRAP** — run Phase 1 (kapp foundation, converge-gated) → Phase 2 (ArgoCD + factory) → wait
     until the cluster is **self-managing** (ArgoCD Synced + Healthy, foundation Ready).
  3. **TEST** — run the **test suites** (foundation health, ArgoCD app health, a smoke workload, and
     the DR/failover smoke where applicable). Success is gated on these.
  4. **VANISH (on success)** — revoke the one-time bootstrap privileges, delete the ephemeral RG / ACI /
     identity (self-destruct). The permanent, ArgoCD-managed cluster remains, self-managing.
  5. **On FAILURE — do NOT vanish.** Keep the scaffolding + logs for diagnosis; resume with `--resume`.
- **Idempotent + resumable + gated** — re-runnable; resumes from the last step; physical/manual steps
  (on-prem PVE install, wiring) pause as operator-confirmed gates.

### Why Azure + ephemeral

- The **AKV bootstrap anchor lives in Azure** → co-locating the runner gives it **workload-identity**
  access with **no secret handoff / no secrets on a laptop**.
- **Self-destruct** = the elevated bootstrap privileges don't linger (security) and there's no
  standing scaffolding to operate (maintainability).
- **Test-gated** = the cluster is proven workload-ready before success is declared and the runner leaves.
- **Off-laptop + reproducible** = anyone can trigger a clean bootstrap; the process is one artifact.

## 7. Per-cluster applicability

- **on-prem-primary / ovh-proving-ground (Proxmox):** the **physical substrate** (PVE/switch/wiring) is
  operator-gated and outside this runner; the Azure bootstrapper drives from the cluster API onward
  (Talos VMs via bpg → kapp foundation → ArgoCD). (OVH is Proxmox → same path as on-prem from k8s up.)
- **contabo-standby / azure-dr:** the runner can drive the substrate too (Terraform), end to end.

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
