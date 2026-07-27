<!--
id:             SPEC-PNPLATFORM-DIRSTRUCT-2026-07-27
status:         approved (brainstorming complete, all sections user-approved)
owner_role:     pn-platform-admin
created:        2026-07-27 (authored in ovh-infra, relocated to pn-platform 2026-07-27)
target_repo:    THIS repo (ProficientNowTech/pn-platform, branch main)
related:        ovh-infra:docs/deployment-platform-design/README.md (the "evolve the 3-tier ArgoCD factory" master design)
                memory: onprem-primary-platform-and-repo-plan, org-stack-primary-site-roadmap
-->

# Design — pn-platform directory structure + cluster registry

## 1. Goal

Define the canonical directory structure of **pn-platform** — the single GitOps repo that
bootstraps the **on-prem primary HA cluster** (`ap-south-2a`) and drives **failover to a Contabo
warm-standby + Azure DR**, plus a **time-boxed OVH proving-ground**. The tree must embody the tiered
bootstrap (substrate → provision → cluster-bootstrap → AKV/ArgoCD seed → 3-tier factory → app → DR)
and reconcile the current `v2`/`main` tree (which still carries the **rejected** api-CLI monorepo)
with the "evolve the 3-tier ArgoCD factory" master design.

## 2. Locked decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | **Cluster inventory = 4** (see registry): `onprem-primary` (full, permanent), `contabo-standby` (VDS, permanent), `azure-dr` (AKS cold, permanent), `ovh-proving-ground` (**time-boxed, decommission by 2026-11-30**). | OVH retires end-Nov-2026 but is a paid live asset for ~4 months → used as a disposable proving-ground, not written off. Contabo (VDS, not VPS) is the durable cloud standby. |
| D2 | **Multi-cluster = a cluster registry as DATA** (`platform/clusters/<name>.yaml`). Stacks defined **once**; the stack-orchestrator stamps `registry × stacks` → Applications. | Clusters run *different subsets* of stacks (not mirrors) → cluster is stack *selection* + values, expressed as data. Matches the factory's data-driven ethos + low-friction KT. |
| D3 | **Providers = by ENVIRONMENT, not hypervisor** (`onprem`, `ovh`, `contabo`, `azure`). A **step library** shares the upper tiers (AKV-seed → argo → factory → app) across providers; the **substrate/networking is provider-specific**. | On-prem *owns* the network (physical switches, Sophos, wiring, corosync-VLAN) — a rich substrate OVH/Contabo/Azure don't have. OVH≈Contabo (provider-managed net); neither ≈ on-prem, even though OVH also runs Proxmox. |
| D4 | **Top-level layout** = `provisioner/` → `infrastructure/` → `platform/` → `application/` → `cli/` → `docs/` (reads top-to-bottom as the bootstrap order). | Legible imperative-vs-GitOps split; stacks defined once, clusters compose them. |
| D5 | **DELETE the rejected api-CLI monorepo:** `api/`, `config/`, `container-orchestration/`, `v0.2.0/`, root `go.mod`, `platform/tenant-clusters/` (KubeVirt), `scripts/bootstrap.sh` (Kubespray). | Rejected in the consolidation; the ArgoCD YAML factory is the interface, not a Go config-engine. |
| D6 | **The `pn` orchestrator CLI is DEFERRED** to its own spec — its *slot* (`cli/`) is reserved here, internals planned later. | User: "mark the cli for further planning." Decisions already taken for it are recorded in §7 so the later spec resumes cleanly. |

## 3. Top-level layout

```
pn-platform/
├── provisioner/          TIER 0 · substrate (Ansible) — PVE host roles + inventory + site.yml
│     roles/ (host-baseline, pve-cluster, pve-network, pve-storage, pve-dns, hardening/sso,
│             node-subnet-*, log-shipping-loki, sg3210 switch)  ·  inventory/{dev,prod}
├── infrastructure/       TIER 1–2 · provision + cluster-bootstrap
│     platforms/proxmox/  (terraform bpg VMs)   ·  talos/ (talconfig.yaml + talhelper + Image Factory)
│     (DROP infrastructure/platforms/{baremetal,cloud} until a real need)
├── platform/             TIER 3–5 · the GitOps factory
│     bootstrap/          (platform-root 'platform-app' · AKV→ESO seed · repositories)
│     clusters/           ★ the cluster REGISTRY (data) — 4 files (§4)
│     project-chart/      (AppProjects + RBAC → Entra/Keycloak groups, per cluster)
│     stack-orchestrator/ (registry × stacks → umbrella Apps: destination + subset + values)
│     stacks/<domain>/    (shared, ONCE: target-chart + charts/ + values-<env>.yaml)
│     hooks/              (health / notifications / validation)
├── application/          TIER 7 · pnats umbrella (+ pnats-ci Argo Workflows)
├── cli/                  ⏸ RESERVED — the `pn` orchestrator (design DEFERRED, see §7)
├── docs/                 design · runbooks · ADRs · ARCHIVED/ (existing quarantine)
└── README.md · AGENTS.md · CLAUDE.md
```

DR is **not** a directory — `azure-dr` is a registry entry selecting the DR subset. Same for the
OVH proving-ground: a registry entry with a decommission date.

## 4. The cluster registry (`platform/clusters/<name>.yaml`)

One schema; each cluster is pure data:

```yaml
name:        onprem-primary
provider:    onprem                  # onprem | ovh | contabo | azure  (by ENVIRONMENT)
role:        primary                 # primary | standby | dr | proving-ground
region:      ap-south-2a
lifecycle:
  status:    building                # planned|building|active|cold|draining|decommissioned
  # decommission_by:  (absent = permanent)
destination: { name: in-cluster }    # ArgoCD target
envs:        [dev, staging, prod, preview]
stacks:      { include: all }        # all | [list] | { exclude: [list] }
values:      { ref: values/onprem-primary/ }
replication: { role: source, targets: [contabo-standby, azure-dr] }
```

The one schema expresses four very different clusters:

| cluster | provider | role | lifecycle | envs | stacks | replication |
|---|---|---|---|---|---|---|
| `onprem-primary` | onprem | primary | permanent | dev/stg/prod/preview | **all** | source → contabo,azure |
| `contabo-standby` | contabo | standby | permanent | prod | app-only subset | replica ← primary |
| `azure-dr` | azure | dr | **cold** (scaled-0) | prod | DR subset | replica (cold-restore-from-blob) |
| `ovh-proving-ground` | ovh | proving-ground | **decommission_by 2026-11-30** | staging | all (rehearsal) | none |

`decommission_by` makes OVH a first-class time-boxed cluster — visible to the orchestrator and any
audit, neither wasted nor forgotten.

## 5. Multi-cluster model

- **stack-orchestrator** reads `clusters/ × stacks/` → for each (cluster, selected-stack, env) stamps
  an ArgoCD Application with that cluster's `destination` + merged `values`.
- **project-chart** reads the registry → per-cluster AppProjects + RBAC (roles → Entra/Keycloak groups).
- **Stacks are defined once** under `platform/stacks/<domain>/`; the registry is the *only* place
  cluster-specific selection/values live. Adding a cluster or moving a stack = a data edit.

## 6. Reconciliation with the current `v2`/`main` tree

- **KEEP:** `platform/` (the 3-tier factory), `infrastructure/platforms/proxmox`, `provisioner/`, `docs/`.
- **DELETE:** `api/`, `config/`, `container-orchestration/`, `v0.2.0/`, root `go.mod`,
  `platform/tenant-clusters/`, `scripts/bootstrap.sh`, `infrastructure/platforms/{baremetal,cloud}`.
- **MIGRATE:** `business/apps/pnats` → `application/`; `business/ci/pnats-ci` → `application/`;
  `business/pipelines/*` (harbor/kyverno) → the `developer-platform` stack.
- **ADD:** `platform/clusters/` (the registry), `cli/` (reserved), the per-cluster `values/` overlays,
  the AKV→ESO seed under `platform/bootstrap/`.

## 7. Providers + the deferred `pn` CLI (decisions already taken — resume from here)

**Provider model (approved):** four env-providers; a step library where the **upper tiers**
(`akv-seed`, `argo-bootstrap`, `factory-sync`, `app-deploy`; self-managed also share the Cilium step)
are shared, and the **lower substrate** (`onprem`: pve/switch/sophos/host-net/corosync-VLAN/wiring/
talos-VMs; `ovh`: proxmox-on-rented + OVH-private-net; `contabo`: VDS + Contabo-private-net;
`azure`: azurerm→AKS) is provider-specific. Seam = "provider gets you to a reachable k8s API + CNI;
shared steps take k8s-API → workload-ready via the factory."

**`pn` CLI (⏸ DEFERRED — decisions locked for the future spec):** thin **Go/Cobra** binary, **full
infra lifecycle** (`pre-bootstrap|bootstrap|add-node|run|apply|status|destroy`), **pluggable
providers**, **idempotent + resumable + gated** (manual/physical steps pause for operator confirm).
Engine = Step/Phase/Runner(mocked in tests)/State-resume/Gate/`--dry-run`. Lives in `cli/` with a
**scoped `cli/go.mod`** (NOT a repo-root Go monorepo). **Guardrail:** owns no config — it orchestrates
existing tools; if a step ever *generates* config, it's regressing toward the deleted api-CLI.
**OVH proving-ground validates the CLI + shared upper tiers + failover; the on-prem physical substrate
is proven only on real hardware.**

## 8. Out of scope

- The `pn` CLI internal implementation (own spec).
- The actual data/app migration from current cross-DC prod → on-prem (own plan; November-deadline).
- The v2 DR watcher relocation off OVH (DR-design task).
- Per-stack contents (the individual stack charts/values) — this spec is structure, not stack authoring.

## 9. Open items / next

- Write the **implementation/migration plan** (writing-plans) for the tree restructure: the ordered
  delete/migrate/add steps against the live `pn-platform` main, so it stays coherent throughout.
- Then (separately) the `pn` CLI spec when we return to it.
