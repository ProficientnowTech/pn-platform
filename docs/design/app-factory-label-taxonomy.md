<!--
id:             DESIGN-PNPLATFORM-LABEL-TAXONOMY-2026-07-27
status:         design (feeds the P1 app-factory chart plan)
target_repo:    THIS repo (ProficientNowTech/pn-platform, branch main)
related:        docs/design/cluster-bootstrap-orchestration.md
                docs/design/directory-structure-and-cluster-registry.md
-->

# Design — the `app-factory` label & annotation taxonomy

## 1. Why this exists

The `app-factory` library chart stamps **every AppProject and every Application** with one consistent
taxonomy, so the whole platform is uniformly discoverable, filterable, RBAC/cost/ordering-addressable —
**regardless of which dependency-layer or AppProject a workload lives in.** This is what lets us divide
stacks *only* by dependency while keeping domain/team/tier as data. **The factory FAILS the render if a
required label is missing** — the taxonomy is enforced, not aspirational.

Two orthogonal dimensions run through everything:
- **AppProject** = RBAC / governance boundary (who may touch it).
- **dependency-layer** = ordering (what must be healthy before it).
An app always carries *both*; ordering keys off the layer **cluster-wide, across AppProjects.**

## 2. Labels (identifying, selectable) — REQUIRED unless noted

### Standard Kubernetes set (`app.kubernetes.io/*`)
| label | value | source |
|---|---|---|
| `app.kubernetes.io/name` | app slug (`harbor`, `cilium`, `pnats-api`) | app entry |
| `app.kubernetes.io/instance` | `<name>-<cluster>` (unique per cluster) | factory-computed |
| `app.kubernetes.io/version` | chart/app version | app entry |
| `app.kubernetes.io/component` | role (`registry`, `cni`, `database`) | app entry |
| `app.kubernetes.io/part-of` | `pn-platform` | factory-default |
| `app.kubernetes.io/managed-by` | `argocd` | factory-default |

### Platform taxonomy (`platform.pnats.cloud/*`)
| label | allowed values | dimension |
|---|---|---|
| `platform.pnats.cloud/domain` | `infrastructure` `storage` `databases` `security` `monitoring` `developer-platform` `data-streaming` `ml-infra` `application` `backup-dr` | **= the AppProject** (RBAC/governance) |
| `platform.pnats.cloud/dependency-layer` | `foundation` `core` `platform` `application` | **ordering** (orthogonal to domain) |
| `platform.pnats.cloud/tier` | `critical` `standard` `best-effort` | criticality/SLO |
| `platform.pnats.cloud/team` | team slug (`platform` `data` `sre` `ml`) | ownership |
| `platform.pnats.cloud/cluster` | `onprem-primary` `contabo-standby` `azure-dr` `ovh-proving-ground` | placement (from the cluster registry) |
| `platform.pnats.cloud/lifecycle` | `active` `experimental` `deprecated` (default `active`) | lifecycle |

## 3. Annotations (metadata, non-selectable)
| annotation | value |
|---|---|
| `platform.pnats.cloud/dependencies` | comma-list of app slugs this needs (the **dependency DATA**, e.g. `cilium,proxmox-csi`) |
| `argocd.argoproj.io/sync-wave` | **factory-DERIVED from `dependency-layer`** (see §4) — never hand-set |
| `platform.pnats.cloud/quota-profile` | `xs` `s` `m` `l` `xl` (drives ResourceQuota/LimitRange) |
| `platform.pnats.cloud/owner` | contact (team/email) |
| `platform.pnats.cloud/docs` | docs URL |
| `platform.pnats.cloud/repo` | source repo URL |

## 4. The ordering rule (layer → wave, factory-computed)

The factory maps `dependency-layer` → `argocd.argoproj.io/sync-wave` so ordering is **data-driven, not
hand-set**:

| dependency-layer | sync-wave band | examples | owned by |
|---|---|---|---|
| `foundation` | −30 … −20 | Cilium, Proxmox-CSI, ESO+AKV store, Vault, ArgoCD | **kapp (bootstrap)** |
| `core` | −10 … 0 | cert-manager, external-dns, ingress/Envoy, NetworkPolicies | ArgoCD |
| `platform` | 10 … 20 | Harbor, Keycloak, monitoring, Kafka/Strimzi, Kargo | ArgoCD |
| `application` | 30 + | pnats umbrella | ArgoCD |

- During **bootstrap**, kapp change-groups enforce the *foundation* order hard (converge-gated).
- In **steady state**, the derived sync-wave is a *soft* hint (ArgoCD reconciles; most apps are
  order-independent). The hard ordering only ever mattered at bootstrap.
- An app's explicit `dependencies` annotation lets the factory *validate* the layer is ≥ each
  dependency's layer (a cheap render-time cycle/ordering sanity check).

## 5. AppProject level

Each AppProject (one per `domain`) carries: the `domain`/`team`/`tier` labels; a
`platform.pnats.cloud/layer-range` annotation (the min–max layer its apps span); the 3 baked RBAC roles
(`admin`/`developer`/`viewer`) bound to Entra/Keycloak groups `pn-<domain>-<role>`; and resource/namespace
whitelists **tightened to what that domain actually deploys** (not `'*'`).

## 6. What the factory enforces (render-time)

1. **Required labels present** — `domain`, `dependency-layer`, `tier`, `team`, `component`; else fail.
2. **Enum validation** — each value is in its allowed set (§2); else fail.
3. **Derived fields** — `instance`, `sync-wave`, `part-of`, `managed-by` computed, never author-set.
4. **Dependency sanity** — every slug in `dependencies` exists and sits at an equal/earlier layer.

## 7. Out of scope
- The chart *implementation* (Helm library templates + helm-unittest) — that's the **P1 plan**.
- Cost/showback tooling that *consumes* these labels — later.
- Kyverno/Gatekeeper policies enforcing the taxonomy cluster-side — later (the factory enforces at
  render; a cluster policy is defense-in-depth for anything applied outside the factory).
