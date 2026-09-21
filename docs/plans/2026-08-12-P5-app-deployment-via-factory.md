<!--
id:             PLAN-PNPLATFORM-P5-APP-DEPLOYMENT-2026-08-12
status:         plan — awaiting approval (DIAGNOSE complete, evidence below; nothing implemented yet)
target_repo:    THIS repo (ProficientNowTech/pn-platform, branch main)
design:         docs/design/app-factory-label-taxonomy.md · app-factory-values-schema.md
                docs/design/cluster-bootstrap-orchestration.md §3, §5
follows:        docs/plans/2026-07-27-P1-app-factory-chart.md (the library chart this consumes)
-->

# P5 — App deployment via the `app-factory`: flat, independent Applications

## 1. Goal

Deploy the platform's applications as **independent ArgoCD Applications ordered by a flat
`dependency-layer` label** — the explicit opposite of a nested stack-orchestrator hierarchy. P1 built the
library chart; nothing consumes it yet. This plan defines what consumes it, and retires the stale root
that still points at the rejected model.

**The rule this plan exists to make real** (`cluster-bootstrap-orchestration.md` §3): *"flat
grouping-by-dependency, expressed as data — not a nested Application hierarchy."* `dependency-layer` is
the **only** ordering fact a human authors; the factory compiles it into BOTH
`argocd.argoproj.io/sync-wave` and `kapp.k14s.io/change-group|change-rule` so ArgoCD and kapp agree
without two authored sequencing facts.

`stack-orchestrator` is **not** deleted by this plan: the design keeps it as the multi-cluster *stamper*
(registry × stacks → Applications with destination + values, `directory-structure-…` D2/§5). What is
rejected is its use as the **ordering** mechanism. Those are different jobs and this plan only replaces
the second.

## 2. Diagnosis — verified, with evidence

Established by inspection of this repo and the live interim cluster:

| # | Finding | Evidence |
|---|---|---|
| F1 | The `app-factory` chart is implemented and tested | `platform/app-factory/`: 6 helpers (`_application`, `_appproject`, `_labels`, `_syncwave`, `_validate`, `_enums`), `values.schema.json`, `schemas/app-entry.schema.json`, 6 helm-unittest files under `tests-consumer/` |
| F2 | **Nothing consumes it in anger** | the only consumer is `app-factory/tests-consumer/` (a test harness). No real app catalogue exists |
| F3 | Foundation values are byte-identical to the proven live cluster | `10-cilium/values.yaml` sha `90639f24be18f391` == `ovh-infra:onprem/platform-live:…/cilium/values.yaml`; `30-external-secrets` and `40-argocd` both diff to **0 lines** |

### Defects found while diagnosing — each blocks or misleads

**D1 — the foundation renders `Certificate` CRs but installs no cert-manager CRDs.**
`10-cilium/values.yaml` sets `hubble.tls.auto.method: certmanager` with a `certManagerIssuerRef`, so the
render emits `cert-manager.io/v1 Certificate` objects. `render.sh` emits only `cilium · proxmox-csi ·
proxmox-ccm · external-secrets · argocd` — nothing provides those CRDs, and cert-manager itself arrives
later via ArgoCD. On a fresh cluster `kapp deploy` fails applying an unknown kind.
*This is not speculative:* the same values hit the same wall on the interim cluster, where the fix was to
apply the cert-manager CRDs **before** the CNI — the CNI cannot install at all otherwise, so no node ever
reaches Ready. `helm template` does not catch it (it never contacts the cluster), which is exactly why it
survived unit testing.

**D2 — the ArgoCD chart is vendored unpinned.**
`vendor-charts.sh` pins cilium (`1.17.17`) and external-secrets (`0.20.4`) but runs
`helm pull argo/argo-cd --untar` with **no `--version`**. Vendoring on two different days yields two
different ArgoCD versions from identical git state — and the foundation is meant to be digest-pinned.

**D3 — the root Application still bootstraps the pre-consolidation world.**
`platform/bootstrap/platform-root.yaml` targets `repoURL: …/pn-infra.git`, `targetRevision: v2`,
`path: platform/project-chart` — a repo that was consolidated into pn-platform, a branch now archived as
`archive/branch/v2`, and the **rejected hierarchy**. It also annotates `deployed-by: platform/deploy.sh`,
deleted in P0. Applying this file would sync the very model this plan replaces.

**D4 — cut tooling still present.** `platform/bootstrap/` carries `install-sealed-secrets.sh` and
`install-argo.sh` (+ `.backup`). Sealed-secrets was explicitly cut ("superseded → AKV→ESO→Vault"), and
imperative install scripts are what P2's kapp foundation replaces.

## 3. What this plan does NOT do

- Does not delete `stack-orchestrator/` or `project-chart/` — they remain the multi-cluster stamper and
  the AppProject/RBAC generator per D2/§5. Only their use as an *ordering hierarchy* ends.
- Does not author the individual stack charts (`directory-structure-…` §8 puts that out of scope).
- Does not change the foundation's ordering: kapp owns hard ordering during bootstrap; layers are a soft
  hint in steady state.

## 4. Tasks

### A — make the root truthful (prerequisite; nothing else is safe while D3 stands)
- **A1** Repoint the root at this repo/branch and at `platform/root/` (the P4 chart), retiring the
  `pn-infra v2 → project-chart` source. Preserve `sync-wave: -100`.
- **A2** Delete `install-sealed-secrets.sh`, `install-argo.sh`, `install-argo.sh.backup` (D4). Record in
  the commit why, so their absence is not later read as an accident.
- **A3** Assert in CI that no manifest references `pn-infra.git`, `targetRevision: v2`, or
  `platform/deploy.sh`. D3 survived a consolidation *and* a P0 tree reconciliation; a test is what stops
  it returning.

### B — the app catalogue as data
- **B1** Define the catalogue location and shape: one entry per app, carrying only the **authored** fields
  from `app-factory-values-schema.md` §1 (`name, domain, version, team, tier, dependency-layer` required;
  `dr-role, lifecycle, contact, dependencies, source, syncPolicy` optional). `cluster`, `environment`,
  `destination` come from context, never repeated per app.
- **B2** Assign `dependency-layer` for every app, and justify each non-`platform` assignment in one line.
  Default to `platform`; `foundation` is reserved for what kapp already owns. The layer count staying
  small is the design's stated reason this never becomes a hierarchy — treat every new layer as suspect.
- **B3** Encode `dependencies` where a real edge exists, and let `_validate` enforce layer monotonicity
  against it (P1 Task 3/7). An edge that does not cross a layer boundary is documentation, not ordering.

### C — migrate the proven live apps
The interim cluster runs **17 flat, independent Applications** that already match this model in shape
(one file, one Application, no nesting) and are proven Synced+Healthy across repeated from-scratch
rebuilds. They are the highest-confidence input available.
- **C1** Convert each to a factory app entry. Expected mapping: `cilium, proxmox-csi/ccm,
  external-secrets → foundation` (kapp owns them; they appear in the catalogue for labelling/discovery,
  not for ordering); `cert-manager, dns, node-local-dns → core`; `external-dns, ingress, envoy-gateway,
  cilium-lb, argocd → platform`.
- **C2** Carry forward the two hard-won ArgoCD facts from those apps, or they will be relearned:
  the CNI runs with **no `selfHeal`** (a bad heal cuts the dataplane), and an app with no `automated`
  block is **never adopted** by ArgoCD — it never receives the `argocd.argoproj.io/instance` tracking
  label and therefore reports OutOfSync forever against byte-identical content. Any factory-stamped app
  that is deliberately non-automated needs an explicit one-time adoption, or its status is a permanent
  false alarm and "all apps Synced" stops meaning anything.
- **C3** Reconcile the catalogue against the live cluster: every live app present, no invented apps.

### D — prove it
- **D1** Render the catalogue; assert every Application carries all 9 labels and that the derived
  `sync-wave` matches the layer map (`foundation −25 · core −5 · platform 10 · application 30`).
- **D2** Assert the kapp annotations derived from the same layer agree with the sync-wave — the design's
  whole claim is that one authored fact drives both.
- **D3** Diff the rendered Applications against the live cluster's 17. A difference is either a migration
  bug or an undocumented live drift; both need naming before this is adopted.
- **D4** Acceptance: on the proving target, the factory-rendered platform reaches all-Synced+Healthy with
  no manual intervention, and the four readiness gates used on the interim cluster still pass — nodes
  Ready, all apps Synced+Healthy, ingress serving from the public internet, and a PVC that binds and
  mounts. "The render is valid" is not the gate; a converged cluster is.

## 5. Acceptance criteria

1. No manifest in the repo references `pn-infra.git`, `v2`, or `platform/deploy.sh`, and CI enforces it.
2. Every app is declared once, as data, with exactly one authored ordering fact (`dependency-layer`).
3. `sync-wave` and the kapp `change-group`/`change-rule` for a given app are both derived from that one
   fact and are consistent.
4. No nested Application hierarchy is introduced anywhere.
5. The factory-rendered platform converges on the proving target and passes the four readiness gates.

## 6. Risks

| Risk | Why it matters | Mitigation |
|---|---|---|
| D1 blocks the foundation on a fresh cluster | the CNI cannot install → no node reaches Ready → nothing else runs | fix cert-manager CRD ordering before any target-cluster run; it is a foundation defect, not an app-layer one |
| Layer proliferation | many layers rebuilds the hierarchy under a new name | justify every non-default layer; the design expects "a handful" |
| Silent non-adoption | a non-automated app reports OutOfSync forever and poisons "all apps Synced" as a signal | C2 — explicit adoption for any deliberately non-automated app |
| Catalogue drifts from the live cluster | the repo describes a platform nobody is running | D3 diff, and re-run it whenever the catalogue changes |
