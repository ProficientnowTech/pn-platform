# pn-platform

The single GitOps platform repo for ProficientNow — it bootstraps and governs the on-prem primary
Kubernetes cluster (Talos on Proxmox) and drives failover to the cloud standby/DR clusters.

## Layout

| Directory | Responsibility |
|---|---|
| `provisioner/` | Ansible — host/substrate config (PVE, networking, hardening) and the ephemeral bootstrapper (`provisioner/bootstrapper/`, P3). |
| `infrastructure/` | Terraform (bpg/proxmox) + Talos — VM provisioning; the converge-gated kapp foundation (`infrastructure/bootstrap/`, P2). |
| `platform/` | The ArgoCD deployment factory: the `app-factory` library chart (P1), the cluster **registry** (`platform/clusters/`), `project-chart`, `stack-orchestrator`, and `stacks/<domain>/`. |
| `application/` | Business workloads (pnats) + their CI. |
| `cli/` | Reserved — the `pn` orchestrator (design deferred). |
| `docs/` | Design (`docs/design/`), plans (`docs/plans/`), standards, runbooks, and the fuma-docs site. |

## The model

A cluster is brought up **sovereignly** and reconciled by GitOps — no imperative CLI:

1. **Substrate** (Ansible): PVE cluster, VLANs, storage, hardening.
2. **Bootstrap** (the ephemeral bootstrapper, P3): Talos VMs (bpg) → `talosctl bootstrap` → the
   **kapp foundation** (P2: Cilium → Proxmox-CSI → ESO → ArgoCD, converge-gated) with secrets from an
   in-runner **ephemeral Vault** (seeded from SOPS + an operator age key — zero Azure).
3. **Hand-off** (P4): ArgoCD + the **app-factory** (P1) deploy the platform/apps ordered by a flat
   `dependency-layer` label; the bootstrapper migrates secrets to the in-cluster Vault, repoints ESO,
   and self-destructs after the test suite passes.

Multi-cluster is **data**: one file per cluster in `platform/clusters/` (the registry); stacks are
defined once and stamped registry × stacks.

## Where to start

- **Design:** `docs/design/{directory-structure-and-cluster-registry,cluster-bootstrap-orchestration,app-factory-label-taxonomy,app-factory-values-schema}.md`
- **Plans:** `docs/plans/2026-07-2{7,8}-P{0..4}-*.md` (P0 tree reconciliation → P4 hand-off + tests)
- **Live reference configs:** ovh-infra `onprem/platform-live:infrastructure/talos/`

> **Note (P0, 2026-07-28):** the previous api-CLI / Packer / Kubespray imperative flow (`api/`,
> `config/`, `container-orchestration/`, `platform/run.sh`, `infrastructure/deploy.sh`) has been
> **removed**. Historical planning docs are quarantined under `docs/ARCHIVED/`.
