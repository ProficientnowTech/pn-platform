# Implementation Progress — pn-platform bootstrap & factory (P0–P4)

Live tracker for the P0–P4 build. **Plans:** `docs/plans/2026-07-2{7,8}-P{0..4}-*.md`. **Design:** `docs/design/`.

| Plan | Scope | Status |
|---|---|---|
| **P0** | Tree reconciliation | ✅ **DONE** (2026-07-28) |
| **P1** | `app-factory` library chart | ⏳ **next** (cluster-free, helm-unittest) |
| **P2** | kapp foundation | ⬜ cluster-free parts buildable; real-cluster acceptance **blocked on target** |
| **P3** | ephemeral bootstrapper | ⬜ cluster-free parts buildable; acceptance **blocked on target** |
| **P4** | hand-off + test suite | ⬜ cluster-free parts buildable; live asserts **blocked on target** |

## Execution gate
No execution/target cluster is assigned. The productized bootstrap builds the **new on-prem cluster that
replaces the interim `onprem-s2a`**; redone for 3-node HA at node-C join. Cluster-free unit tests
(helm-unittest, `kapp --dry-run`, kind, bats, `terraform validate`) run **now**; the PVE-dependent
converge is the documented acceptance gate (each of P2/P3/P4's final task).

## P0 — what shipped
- Deleted the **old imperative flow**: api-CLI monorepo (`api/ config/ container-orchestration/ v0.2.0/ go.mod`),
  `platform/run.sh`, `platform/tenant-clusters/`, the Kubespray `bootstrap.sh`, and the whole old
  `infrastructure/` Packer/TF provisioning (`deploy.sh` + `platforms/{baremetal,cloud,proxmox}` + `environments/`).
- Migrated `business/ → application/` (pnats + ci + environments); fixed 4 stale `business/` source-paths;
  moved Tekton `pipelines/ → developer-platform/`.
- Scaffolded the cluster **registry** (`platform/clusters/`, 3 clusters — no OVH), the **app-factory**
  library-chart stub, reserved `cli/`, fixed `.gitignore`.
- Fixed stale docs: rewrote the root `README.md`; bannered `cni-architecture.md`,
  `multi-cluster-network-architecture.md`, `validation.md` as superseded.
- Recovery tag: `archive/pre-P0-reconciliation`.

## Deferred / flagged
- **Tekton pipelines** (now under `developer-platform/`): slated for replacement by Argo Workflows — delete at CI/CD-stack time.
- Root `README.md` rewritten; deep inline `./run.sh` mentions inside the bannered network docs left as historical.

## Notes
- Design SSOT: `docs/design/{directory-structure-and-cluster-registry,cluster-bootstrap-orchestration,app-factory-label-taxonomy,app-factory-values-schema}.md`.
- Live reference configs reused by P2–P4: ovh-infra `onprem/platform-live:infrastructure/talos/`.
