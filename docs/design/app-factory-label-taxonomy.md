<!--
id:             DESIGN-PNPLATFORM-LABEL-TAXONOMY-2026-07-27
status:         design (requirements-gathered + researched); feeds the P1 app-factory chart plan
target_repo:    THIS repo (ProficientNowTech/pn-platform, branch main)
process:        11 confirmed requirements → small research workflow (3 agents) → this
related:        docs/design/cluster-bootstrap-orchestration.md
-->

# Design — the `app-factory` label & annotation taxonomy (minimal)

**9 labels cover all 11 confirmed needs. Nothing is added "because the convention has it."** One custom
prefix (`platform.pnats.cloud/`), flat keys — mirroring how Kubernetes sub-namespaces its own labels.
The `app-factory` chart stamps these on every AppProject + Application and **fails the render** if a
required one is missing/invalid.

## The 9 labels

| Label | Values | Serves |
|---|---|---|
| `app.kubernetes.io/part-of` | the domain / capability grouping (= the AppProject) | #9 discovery |
| `app.kubernetes.io/version` | chart/app semver or hash | #6 provenance (version half) |
| `platform.pnats.cloud/team` | team slug (small closed set) | **#3 RBAC + #4 ownership + #9** |
| `platform.pnats.cloud/environment` | `dev` `staging` `prod` `preview` | #2 delivery + #9 |
| `platform.pnats.cloud/tier` | `critical` `high` `standard` `low` | #7 criticality/SLO + #9 |
| `platform.pnats.cloud/cluster` | cluster-registry key (`onprem-primary` …) | #12 placement + #9 |
| `platform.pnats.cloud/dr-role` | `none` `source` `replica` | **all of #13** (`dr-critical` = `dr-role != none`) |
| `platform.pnats.cloud/lifecycle` | `active` `experimental` `deprecated` | #14 + #9 |
| `platform.pnats.cloud/dependency-layer` | `foundation` `core` `platform` `application` | #1 ordering (→ annotations, §Ordering) |

**Reuse is the whole game:** `team` serves 3 needs; `dr-role` collapses "DR-critical" + role into one enum;
#9 (discovery = domain/team/tier/cluster/lifecycle) costs **zero net-new labels** — those five already exist.

## The annotations (metadata — must NOT be selectable labels)

| Annotation | Value | Source |
|---|---|---|
| `argocd.argoproj.io/sync-wave` | derived from `dependency-layer` | factory-computed |
| `kapp.k14s.io/change-group` + `change-rule` | derived from `dependency-layer` | factory-computed (bootstrap) |
| `kargo.akuity.io/authorized-stage` | `<kargo-project>:<stage>[,…]` | authored (a consent gate; one app may authorize several stages, so it isn't derived from `environment`) |
| `platform.pnats.cloud/contact` | Slack channel / on-call alias | authored — the human detail `team` (a slug) deliberately doesn't carry |

Nothing else — no changelog, doc-link, or description annotation (no requirement asks for them).

## Ordering (#1) — one authored fact

`dependency-layer` is the **only** thing a human writes for ordering. The factory's render step compiles it
into both tool-native annotations so ArgoCD and kapp agree without two authored sequencing facts:
- `argocd.argoproj.io/sync-wave: <layer→wave>` (steady-state reconcile), and
- `kapp.k14s.io/change-group` + `change-rule` (bootstrap converge order).

Layer → wave: `foundation −25 · core −5 · platform 10 · application 30`. During bootstrap kapp enforces the
foundation order hard; in steady state the wave is a soft hint (most apps are order-independent).

## What we deliberately left OUT (and why)

- **`app.kubernetes.io/{name,instance,component,managed-by}`** — no discriminating value here:
  `metadata.name` already gives identity; `managed-by` would always read `argocd`. Adding them is the
  sprawl the brief forbids.
- **Source repo (#6)** — needs **no** label/annotation: it's already a structured field
  (`Application.spec.source.repoURL` / `targetRevision`), natively queryable. Only *version* is a label,
  because you select *across* apps on it ("everything still on 5.7.x"). One fact, one home.
- **Quota, observability-correlation, cost labels** — dropped by you; not a requirement.
- **High-cardinality values** — every label here is a small closed enum or a bounded registry key
  (`version` is semver/hash, never a per-commit SHA) to keep the label index cheap.

## One honest limitation to document

**RBAC (#3) is label-*assists-a-name*, not live label-based RBAC.** ArgoCD binds groups to AppProject
*names* today (label-based RBAC is an unmerged proposal). So `team` is the input the factory uses to
*generate* the AppProject + its `pn-<scope>-<role>` group bindings, and to catch drift if an AppProject
is hand-edited to disagree with its Applications' `team` — not a policy ArgoCD evaluates at auth time.

## Enforcement (#5) — a consumer, not a slice

A Kyverno `ClusterPolicy` (`validationFailureAction: Enforce`) whose `pattern.metadata.labels` lists these
9 keys (`"?*"` for required-non-empty; enum checks for `tier`/`dr-role`/`lifecycle`). Defense-in-depth for
anything applied outside the factory; the factory's render-time `fail` is the first gate. **Zero new labels.**

## Out of scope
- The chart *implementation* (Helm library + helm-unittest) — the **P1 plan** (must be re-aligned to *this* set).
- The Kyverno policy manifest + the tier→PDB/HPA/NetworkPolicy default bundles — later.
