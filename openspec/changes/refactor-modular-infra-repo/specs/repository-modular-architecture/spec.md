## ADDED Requirements

### Requirement: Repository Module Layout
The repository SHALL expose the following top-level modules with clearly documented responsibilities: `api/`, `config/`, `infrastructure/`, `provisioner/`, `container-orchestration/`, `platform/`, `business/`, and `docs/`. Each module MUST contain its own README explaining its role and how it consumes the shared APIs.

#### Scenario: Engineer discovers module ownership
- **WHEN** a new engineer reads the repository root
- **THEN** they see the eight module directories listed above
- **AND** each module README names the APIs it provides/consumes so work can be scoped without hunting through unrelated folders.

### Requirement: Central Go API CLI for Schemas and Generators
The `api/` module MUST own all YAML schemas, definitions, and validation/generation tooling (stored directly under `api/schemas/` and `api/definitions/`) within a single repository-wide Go module. It SHALL provide a Go-based CLI binary that outputs environment configs, inventories, Ansible vars, and provisioner build artifacts used by downstream modules, eliminating duplication of schema logic elsewhere and enabling distribution via Git/GitHub releases.

#### Scenario: Generating a development environment bundle
- **WHEN** an engineer runs `api/bin/api generate env --id development`
- **THEN** the command validates the `development` definitions against the schemas and writes the resulting configs (e.g., `environments/development.config.yml`, inventories, group vars) into a documented output directory for other modules to consume.

### Requirement: Shared Configuration Module
The repository SHALL include a `config/` module that stores reusable configuration bundles via manifests (`packages/<id>/package.json`) that declare version metadata. Each module’s `environments/` files MUST reference a config package ID from `config/` rather than embedding duplicate configuration, and releases/tags provide versioning instead of directory names.

#### Scenario: Environment references config package
- **WHEN** an engineer inspects `infrastructure/environments/development.yaml`
- **THEN** the file references a config package such as `config/packages/core`
- **AND** the API CLI resolves that package to render the full environment configuration.

### Requirement: Infrastructure Platform Abstraction (MVP)
The `infrastructure/` module SHALL organize assets into `environments/` and `platforms/<platform>/<provider>/`. The MVP MUST relocate the existing Proxmox/Terraform implementation to `platforms/proxmox/terraform/` and ensure it reads environment + role data from the `api/` outputs and the referenced config package. Slots for `baremetal/libvirt` and `cloud/{aws,gcp,azure}` SHALL exist, even if empty.

#### Scenario: Terraform uses API artifacts
- **WHEN** the Proxmox Terraform code runs from `infrastructure/platforms/proxmox/terraform`
- **THEN** it reads host definitions, networking, and credentials from the API-generated files and config package (rather than private bootstrap directories)
- **AND** engineers can point configs in `infrastructure/environments/` at other platforms once they exist.

### Requirement: Provisioner Template Pipeline
The `provisioner/` module SHALL provide a templating pipeline that consumes role definitions + environment overrides and produces image artifacts with both static (shared per role) and dynamic (per node) configuration handled. Provisioner builds MUST be invoked via the `api` CLI, and outputs MUST include metadata descriptors (e.g., JSON manifest with role, version, artifact location) that infrastructure platforms can reference, including placeholders for future remote object storage destinations.

#### Scenario: Role image build
- **WHEN** `api/bin/api provision build --role k8s-master --env development` runs
- **THEN** it reads schemas/definitions via the API, applies static configuration (packages, kernel tweaks) plus dynamic data (hostnames, IPs), packages the resulting image/systemd bootstrap scripts, and writes a metadata file that Terraform can consume.
- **AND** the metadata includes optional fields for remote object storage endpoints even if upload automation is not yet implemented.

### Requirement: Container-Orchestration Provider Interface (MVP)
The `container-orchestration/` module MUST expose a provider interface where each provider resides under `providers/<name>/` with standardized `deploy/reset/validate` entrypoints and documentation. The current Kubespray flow SHALL live under `providers/kubespray/` and consume inventories/vars from the API outputs. Stubs for `kubekey` and `kind` SHALL be present for future work.

#### Scenario: Kubespray deploy uses provider contract
- **WHEN** an engineer runs `container-orchestration/providers/kubespray/deploy.sh --env development`
- **THEN** the script loads the API-generated inventory, runs Kubespray from within its provider directory, and records status via the shared interface so platform automation does not call bespoke scripts.

### Requirement: Platform, Business, and Docs Separation
The `platform/` module SHALL focus on cluster bootstrap, stack orchestration, and shared services, treating the container-orchestration provider as its upstream dependency. Application workloads, Helm charts, and GitOps manifests for business domains MUST live under a new `business/` module that depends on the APIs exposed by `platform/`, and business workloads SHALL be deployed via an app-of-apps chart under `business/charts/`. The `docs/` module MUST capture architecture references, runbooks, module overviews, and include a scaffolded `fuma-docs` application (ready to be hosted on the platform once live).

#### Scenario: Business app deployment flow
- **WHEN** a business team adds a new Helm chart under `business/apps/payments`
- **THEN** the chart references namespaces/secrets exposed by `platform/` APIs, is included automatically via the `business/charts/app-of-apps` Application, and the platform module itself remains agnostic of the business app, ensuring the workload layer can evolve independently.
- **AND** the `docs/` module contains guidance on how the business chart pipeline works, how the `fuma-docs` application is scaffolded/configured, and how to reference platform APIs.
