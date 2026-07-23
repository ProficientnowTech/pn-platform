## 1. API Module Baseline
- [x] 1.1 Inventory existing schemas/definitions/scripts in `infrastructure/modules/bootstrap`, `kubernetes/`, `templates/provisioner`, etc., and map them to their new homes.
- [x] 1.2 Promote the repository to a Go monorepo (root `go.mod`) so `api/cmd/api` can be built/run from anywhere and future packages share the same module.
- [x] 1.3 Create the `api/` module structure with `cmd/api`, `internal/commands`, `schemas/`, `definitions/`, `generators/`, and `outputs/` (no versioned subdirectories).
- [x] 1.4 Port validation logic into Go (yaml-validator integration) and expose `api validate <object>` commands; add unit tests that cover schema loading and validation failures.
- [x] 1.5 Implement `api generate env --id <env>` command that resolves config package references, validates definitions, and writes inventories/group vars to `api/outputs/<env>/`; include smoke tests using the development environment.
- [x] 1.6 Implement `api provision build --role <role> --env <env>` that orchestrates provisioner builds (see Section 4), ensuring build metadata is captured in `api/outputs/<env>/provisioner/`.
- [x] 1.7 Provide developer docs + examples inside `api/README.md` describing commands, required environment variables, and how other modules consume outputs.

## 2. Shared Config Module
- [x] 2.1 Create `config/` with `packages/<id>/package.json` manifests describing package metadata (version string, environments, file mappings).
- [x] 2.2 Migrate existing per-module configs (networking, Terraform variables, provisioner overrides, Kubespray vars, platform settings) into packages referenced by ID (version tracked via manifest + Git releases).
- [x] 2.3 Add tooling (Makefile target or script) to validate config manifests and optionally enforce version bumps when manifests change.
- [x] 2.4 Update each module’s `environments/<env>.yml` to reference a config package ID instead of embedding config or pointing to versioned directories.
- [x] 2.5 Document how to create/upgrade a config package, how releases provide versioning, and how `api generate` resolves packages, including examples for development and production.

## 3. Infrastructure Module Restructure (MVP: Proxmox/Terraform)
- [x] 3.1 Move Terraform assets from `infrastructure/modules/nodes` into `infrastructure/platforms/proxmox/terraform` and adjust module paths/imports.
- [x] 3.2 Add `infrastructure/environments/` pointing to config packages + API outputs (inventories, provisioner metadata); create development environment definition as reference.
- [x] 3.3 Update Terraform variables and data sources to read from the new API output directories (hosts, networks, image metadata) instead of legacy bootstrap paths.
- [x] 3.4 Provide scaffolding directories for `platforms/baremetal/libvirt` and `platforms/cloud/{aws,gcp,azure}` with README placeholders describing how to implement providers later.
- [x] 3.5 Update helper scripts (e.g., `run.sh`, `validate.sh`) to call the API CLI before Terraform applies and to surface config-package/version info in logs.
- [x] 3.6 Document the new infrastructure workflow (generate → provision → terraform apply) in `infrastructure/README.md`.

## 4. Provisioner Module Completion
- [x] 4.1 Relocate `infrastructure/modules/templates/provisioner` to top-level `provisioner/` preserving existing Ansible content, playbooks, and docs.
- [x] 4.2 Define provisioner environment configs referencing config packages and API outputs; ensure static vs dynamic data is clearly separated.
- [x] 4.3 Implement metadata emission (JSON/YAML) describing role, version, artifact path, checksum, and optional remote storage fields (left unimplemented) for each build.
- [x] 4.4 Create hooks/placeholders for remote object storage upload (e.g., S3) without enabling uploads yet; document how they would be wired once ready.
- [x] 4.5 Update provisioner docs (ORCHESTRATION, IMPLEMENTATION_PLAN) to reflect API-driven invocation flow and new config references.
- [x] 4.6 Add automated tests or scripts to verify that building a sample role produces the expected filesystem layout + metadata.

## 5. Container-Orchestration Module (MVP: Kubespray)
- [x] 5.1 Migrate `k8s-cluster/` and `kubernetes/` scripts into `container-orchestration/providers/kubespray` with standardized `deploy/reset/validate` entrypoints.
- [x] 5.2 Ensure the Kubespray provider consumes inventories/group vars exclusively from `api/outputs/<env>/` and references config packages for provider-specific settings.
- [x] 5.3 Define provider interface docs (expected scripts, environment variables, outputs) and add placeholder directories for `providers/kubekey` and `providers/kind` with README instructions.
- [x] 5.4 Update automation (CI scripts or Make targets) to call the provider via the new interface and surface logs/artifacts consistently.

## 6. Platform, Business, and Docs Modules
- [x] 6.1 Update `platform/` scripts/charts to call the container-orchestration provider via the API outputs (rather than invoking Kubespray directly) and confirm stack orchestrator references still resolve.
- [x] 6.2 Relocate business workloads into `business/` (apps, charts, pipelines) and build an app-of-apps chart under `business/charts/cluster-apps` that deploys all business charts automatically.
- [x] 6.3 Create/expand the `docs/` module with architecture references, runbooks, module READMEs, and scaffold the `fuma-docs` application (Helm chart or Argo Application) ready to be hosted on the platform.
- [x] 6.4 Update top-level `README.md` (and module READMEs) to outline the new directory structure, config referencing model, and API usage patterns.

## 7. Validation & Migration Support
- [x] 7.1 Write migration notes describing how existing environments map into the new config packages and how engineers transition scripts/workflows.
- [x] 7.2 Provide helper scripts to backfill existing generated artifacts into `api/outputs/` for environments already deployed.
- [x] 7.3 Run an end-to-end test in the development environment (API generate → provisioner build → Terraform apply → Kubespray deploy → platform bootstrap → business app-of-apps sync) and capture results/logs in `docs/validation.md`.
- [x] 7.4 Ensure `openspec validate refactor-modular-infra-repo --strict` passes and document verification steps in the change log.
