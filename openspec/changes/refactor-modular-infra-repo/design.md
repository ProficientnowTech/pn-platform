## Context
The repository currently mingles schemas (`infrastructure/modules/bootstrap`), provisioning assets (`infrastructure/modules/templates/provisioner`), Terraform (`infrastructure/modules/nodes`), Kubespray helpers (`kubernetes/`, `k8s-cluster/`), and platform/business workloads (`platform/`). Engineers must understand tool-specific folder conventions merely to add a role or environment. There is also no central place to version reusable configuration bundles, and the “API” is a set of bash scripts rather than a consumable binary. We need a layered architecture so that: (1) specifications, schemas, and generators live in one Go-based API module, (2) versioned configuration bundles sit in a shared `config/` module that each module’s `environments/` references, (3) infrastructure platforms consume API artifacts via stable contracts, (4) provisioner templates handle static/dynamic role config triggered by the API, (5) container orchestration modules deploy Kubernetes using outputs from the lower layers, and (6) platform/business layers depend on the orchestration API rather than bespoke scripts while documentation stays centralized.

## Goals
- Provide a top-level module layout (`api`, `config`, `infrastructure`, `provisioner`, `container-orchestration`, `platform`, `business`, `docs`) with documented responsibilities.
- Deliver an MVP implementation that supports the current Proxmox/Terraform stack and Kubespray deployment flow end to end through the new APIs.
- Make schema/definition validation and artifact generation accessible through a single Go CLI so downstream modules do not copy scripts.
- Introduce config packages referenced by each module’s `environments/`, with versioning handled via package manifests + Git releases (not directory names).
- Preserve existing functionality (development environment cluster) while refactoring in-place and prepare (but do not yet execute) remote image upload hooks.
- Ensure business workloads deploy via an app-of-apps chart in `business/charts/`.

## Non-Goals
- Adding new infrastructure providers beyond scaffolding (bare metal/libvirt, AWS/GCP/Azure) in this change.
- Implementing additional container orchestrators beyond Kubespray, though directory stubs should exist.
- Replatforming business workloads; only directory moves/contract alignment happen now.

## Decisions
1. **API Ownership + Go Monorepo**: All schemas/definitions/validators move into `api/`, which becomes a Go CLI built from the repository-wide `go.mod`. Commands such as `api generate env --id development`, `api validate roles`, and `api provision build --role k8s-master --env development` are available everywhere, and other modules reference artifacts under `api/outputs/...` instead of bespoke scripts.
2. **Schema/Layout Versioning via Releases**: `api/` stores schemas and definitions directly under `api/schemas/` and `api/definitions/`. Versioning is captured in Git tags/releases and metadata files rather than directory names, keeping the repo simple while remaining release-ready.
3. **Shared Config Module**: A top-level `config/` module contains reusable configuration bundles (manifest per package). Every module keeps `environments/` files that reference a config package ID plus any module-local overrides; version bumps occur by updating the manifest + release notes, not by creating new directories.
4. **Infrastructure Layout**: `infrastructure/` gains `environments/` and `platforms/<platform>/<provider>/`. Terraform for Proxmox becomes `platforms/proxmox/terraform` and pulls host/image data from the API/provisioner outputs and the config package referenced by the selected environment.
5. **Provisioner Module**: The existing Ansible-based template system becomes `provisioner/`. Static config (shared per role) stays in role definitions; dynamic config (per node) is attached at render time via environment overrides resolved via the API + config module. Provisioner builds are invoked through the API CLI so the API orchestrates both validation and image construction. Outputs (QCOW2/QEMU images + metadata JSON) are stored in `provisioner/outputs/<env>/<role>/` and include metadata fields to later support uploading artifacts to remote object storage (hooks prepared but disabled).
6. **Container Orchestration Interface**: `container-orchestration/providers/<name>/` must expose `deploy.sh`, `reset.sh`, `validate.sh`, and read-only access to inventories/vars provided by the API. Kubespray is migrated first, with Kubekey and Kind stubs ready.
7. **Platform, Business, Docs**: `platform/` continues to own stack orchestration and cluster bootstrap while remaining dependent on the container-orchestration API. Line-of-business applications move to `business/`, which uses an app-of-apps chart under `business/charts/` to deploy workloads automatically. A `docs/` module centralizes architectural references, module guides, runbooks, and includes a scaffolded `fuma-docs` application that will later be hosted on the platform.

## Alternatives Considered
- **Minimal move (status quo + docs)**: rejected because it preserves tight coupling and scattered tooling.
- **Monorepo split**: separating into multiple repos would break GitOps workflows and complicate shared schemas, so we keep a single repo with modular folders.

## Risks / Trade-offs
- **Migration complexity**: Moving directories could break scripts; mitigated by keeping compatibility symlinks/scripts until modules are fully updated.
- **API CLI learning curve**: Engineers must adopt new commands; mitigated via detailed docs and wrappers plus the `docs/` module.
- **Partial provider coverage**: Only Proxmox/Terraform + Kubespray are guaranteed to work initially; future providers rely on engineers following the documented contract.
- **Config package drift**: Config bundles could diverge from environments if manifests/releases are not updated; mitigated by referencing package IDs explicitly in each environment file and documenting release procedures.

## Migration Plan
1. Extract schemas/definitions/validators into `api/` and update existing scripts to call the new CLI.
2. Move Terraform/Proxmox code and adjust paths/imports (ensure generated inventories referenced from `api/`).
3. Promote provisioner assets and update Terraform to consume the new image metadata paths.
4. Relocate Kubespray scripts into `container-orchestration/providers/kubespray` and patch automation to use the API outputs.
5. Update `platform/` references, create `business/`, and move workloads.
6. Run end-to-end tests in the development environment; fix regressions.

## Open Questions
- How should we version schemas vs. definitions inside `api/`? → **Answer**: keep them in stable directories and rely on Git/GitHub releases (metadata) rather than per-directory versions.
- Do we need automation to upload provisioned images to remote object storage as part of the MVP, or is local storage acceptable initially? → **Answer**: prepare metadata/hooks for remote uploads but leave the actual upload automation for a future change.
- Should business workloads adopt ArgoCD Application sets separate from platform stacks during this change or later? → **Answer**: yes, business charts deploy automatically via an app-of-apps pattern under `business/charts/` as part of this change.
