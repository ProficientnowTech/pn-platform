# Spec Delta: repository-modular-architecture

This document shows the changes to the `repository-modular-architecture` spec introduced by the `api-config-separation` change.

---

## MODIFIED Requirement: Central Go API CLI for Schemas and Generators

### Before

```markdown
### Requirement: Central Go API CLI for Schemas and Generators
The `api/` module MUST own all YAML schemas, definitions, and validation/generation tooling (stored directly under `api/schemas/` and `api/definitions/`) within a single repository-wide Go module. It SHALL provide a Go-based CLI binary that outputs environment configs, inventories, Ansible vars, and provisioner build artifacts used by downstream modules, eliminating duplication of schema logic elsewhere and enabling distribution via Git/GitHub releases.

#### Scenario: Generating a development environment bundle
- **WHEN** an engineer runs `api/bin/api generate env --id development`
- **THEN** the command validates the `development` definitions against the schemas and writes the resulting configs (e.g., `environments/development.config.yml`, inventories, group vars) into a documented output directory for other modules to consume.
```

### After

```markdown
### Requirement: Central Go API CLI for Schemas and Generators
The `api/` module MUST own all YAML schemas and validation/generation tooling (stored under `api/schemas/`, `api/templates/`) within a single repository-wide Go module. Configuration definitions SHALL reside in `config/packages/<module>/` instead of `api/definitions/`. The module SHALL provide a Go-based CLI binary that:
1. Loads base configurations (YAML) from `config/packages/<module>/`
2. Loads environment overrides (YAML) from `<module>/environments/<env>.yaml`
3. Validates all configurations against schemas (including environment-specific schemas in `api/schemas/environments/`)
4. Merges base configurations with environment overrides
5. Renders module-native formats (.tfvars, .json, .ini, .yaml) using Go `text/template`
6. Outputs generated files to `api/outputs/<env>/` for downstream module consumption

This enables distribution via Git/GitHub releases and ensures the API module is a pure tool without storing configuration data.

#### Scenario: Generating a development environment bundle
- **WHEN** an engineer runs `api/bin/api generate env --id development --config infrastructure`
- **THEN** the command:
  1. Loads base configs from `config/packages/infrastructure/*.yaml`
  2. Loads overrides from `infrastructure/environments/development.yaml`
  3. Validates overrides against `api/schemas/environments/infrastructure.schema.yaml`
  4. Merges base configs with overrides
  5. Validates merged configs against general schemas
  6. Renders `api/templates/infrastructure/terraform.tfvars.tmpl` with merged data
  7. Writes `api/outputs/development/terraform.tfvars` (HCL format)
  8. Updates `api/outputs/development/metadata.json` with file paths
- **AND** engineers never hand-edit .tfvars files; they only modify YAML configs

#### Scenario: Validating environment overrides
- **WHEN** an engineer runs `api/bin/api validate --target environments`
- **THEN** the command validates all `<module>/environments/*.yaml` files against their corresponding schemas in `api/schemas/environments/<module>.schema.yaml`
- **AND** reports any schema violations (missing required fields, incorrect types, invalid values)
```

**Rationale**: Separates tool (API) from data (config), enforces YAML-only inputs, adds template rendering, and formalizes environment validation.

---

## MODIFIED Requirement: Shared Configuration Module (Master Config Pattern)

### Before

```markdown
### Requirement: Shared Configuration Module
The repository SHALL include a `config/` module that stores reusable configuration bundles via manifests (`packages/<id>/package.json`) that declare version metadata. Each module's `environments/` files MUST reference a config package ID from `config/` rather than embedding duplicate configuration, and releases/tags provide versioning instead of directory names.

#### Scenario: Environment references config package
- **WHEN** an engineer inspects `infrastructure/environments/development.yaml`
- **THEN** the file references a config package such as `config/packages/core`
- **AND** the API CLI resolves that package to render the full environment configuration.
```

### After

```markdown
### Requirement: Shared Configuration Module (Master Config Pattern)
The repository SHALL include a `config/` module with a master configuration package under `config/packages/core/` that declares platform/provider/orchestrator choices and stores all base configuration. The master config (`config/packages/core/config.yaml`) SHALL specify infrastructure platform (Proxmox, AWS, GCP, Azure, bare metal), provider (Terraform, Pulumi), and orchestrator (Kubespray, Kubekey, Kind) selections. Platform-agnostic configs (hosts, networks) SHALL reside at package root, while platform-specific configs SHALL be organized under `platforms/` and orchestrator-specific configs under `orchestrators/`. All configuration MUST be in YAML format, versioned via `package.json` and Git releases, and MUST NOT contain sensitive data. Module environment files reference `configPackage: core` and provide environment-specific overrides and secrets.

#### Scenario: Master config declares deployment choices
- **WHEN** an engineer inspects `config/packages/core/config.yaml`
- **THEN** they see explicit declarations:
  ```yaml
  infrastructure:
    platform: proxmox
    provider: terraform
  container_orchestration:
    orchestrator: kubespray
    provider: docker
  ```
- **AND** the API CLI uses these choices to select appropriate templates and load platform-specific configs

#### Scenario: Platform-agnostic and platform-specific configs
- **WHEN** an engineer inspects `config/packages/core/`
- **THEN** they find:
  - `hosts.yaml`, `networks.yaml` (platform-agnostic, work with any platform)
  - `platforms/proxmox.yaml` (Proxmox-specific settings: endpoint, node_name, datastore)
  - `platforms/aws.yaml` (AWS-specific settings: region, vpc_id, instance_type)
  - `orchestrators/kubespray.yaml` (Kubespray-specific cluster settings)
- **AND** no sensitive data (API tokens, passwords) in any config file

#### Scenario: Switching platforms without code changes
- **WHEN** an engineer wants to deploy on AWS instead of Proxmox
- **THEN** they update `config/packages/core/config.yaml`:
  ```yaml
  infrastructure:
    platform: aws  # Changed from proxmox
    provider: terraform
  ```
- **AND** the API CLI automatically:
  1. Loads `platforms/aws.yaml` instead of `platforms/proxmox.yaml`
  2. Selects `api/templates/infrastructure/aws/terraform/terraform.tfvars.tmpl`
  3. Generates AWS-compatible terraform.tfvars
- **AND** output structure remains consistent regardless of platform choice

#### Scenario: Environment provides secrets and overrides
- **WHEN** an engineer inspects `infrastructure/environments/development.yaml`
- **THEN** the file references the master config package: `configPackage: core`
- **AND** provides environment-specific overrides for the selected platform (Proxmox API token, SSH keys)
- **AND** the API CLI:
  1. Reads master config to determine platform=proxmox
  2. Loads platform-agnostic configs (hosts.yaml, networks.yaml)
  3. Loads platform-specific config (platforms/proxmox.yaml)
  4. Merges with environment overrides
  5. Validates against schemas
  6. Renders platform-specific template
  7. Generates outputs
```

**Rationale**: Master config pattern enables multi-platform support without code changes, clarifies platform/orchestrator choices, organizes configs by deployment target, enforces YAML-only format, separates platform-agnostic from platform-specific settings, and maintains consistent output contract across all platform choices.

---

## ADDED Requirement: Environment Override Schemas

```markdown
### Requirement: Environment Override Schemas
The `api/schemas/environments/` directory MUST contain a schema file for each module (`<module>.schema.yaml`) that defines valid environment-specific overrides. Each module's environment files (`<module>/environments/<env>.yaml`) SHALL be validated against their corresponding schema. Schemas SHALL document required fields (e.g., configPackage, environment), optional overrides, acceptable value ranges, and secret field formats.

#### Scenario: Infrastructure environment validation
- **WHEN** an engineer creates `infrastructure/environments/production.yaml` with:
  ```yaml
  configPackage: infrastructure
  environment: production
  proxmox:
    api_token: "root@pam!prod-token=abc123"
    endpoint: "https://192.168.1.50:8006/api2/json"
    node_name: "pve-prod"
  ```
- **THEN** running `api/bin/api validate --target environments` validates this against `api/schemas/environments/infrastructure.schema.yaml`
- **AND** reports success if all required fields present and valid
- **OR** reports specific errors if fields missing, malformed, or out of range

#### Scenario: Platform secrets validation
- **WHEN** an engineer creates `platform/environments/development.yaml` with secret definitions for ArgoCD and sealed-secrets
- **THEN** validation ensures required secret keys are present and passwords meet minimum length requirements
- **AND** the schema documents which environment variables can be referenced in secret specs
```

**Rationale**: Formalizes environment override contract, enables consistent validation, improves error messages, and documents secret requirements per module.

---

## ADDED Requirement: Go Template Pipeline with Platform/Orchestrator Selection

```markdown
### Requirement: Go Template Pipeline with Platform/Orchestrator Selection
The `api/` module SHALL contain Go `text/template` files organized by platform/provider/orchestrator under `api/templates/infrastructure/{platform}/{provider}/` and `api/templates/container-orchestration/{orchestrator}/` that transform YAML configuration data into module-native formats. The API CLI SHALL read the master config to determine platform/provider/orchestrator selections and select appropriate template paths. Templates MUST accept merged configuration (platform-agnostic + platform-specific + overrides) as input and produce format-specific outputs (.tfvars for Terraform, .json for provisioner, .ini for Kubespray inventories, .yaml for Helm values). Template rendering SHALL occur after validation and before writing to `api/outputs/<env>/`.

#### Scenario: Platform-specific template selection
- **WHEN** the master config specifies `infrastructure.platform: proxmox` and `infrastructure.provider: terraform`
- **THEN** the API CLI selects template path `api/templates/infrastructure/proxmox/terraform/terraform.tfvars.tmpl`
- **AND** when master config changes to `infrastructure.platform: aws`
- **THEN** the API CLI selects `api/templates/infrastructure/aws/terraform/terraform.tfvars.tmpl` instead
- **AND** no code changes required; only master config update needed

#### Scenario: Proxmox terraform.tfvars generation
- **WHEN** the API CLI renders `api/templates/infrastructure/proxmox/terraform/terraform.tfvars.tmpl`
- **THEN** it receives merged YAML data containing:
  - Platform-agnostic: environment, hosts, networks
  - Proxmox-specific: endpoint, node_name, datastore, api_token (from env override)
- **AND** the template iterates over hosts and generates HCL-formatted host blocks with Proxmox-specific fields
- **AND** outputs valid `terraform.tfvars` file that Proxmox Terraform provider can parse
- **AND** engineers never manually edit .tfvars; all changes happen in YAML

#### Scenario: Kubespray inventory.ini generation
- **WHEN** master config specifies `container_orchestration.orchestrator: kubespray`
- **THEN** the API CLI selects `api/templates/container-orchestration/kubespray/inventory.ini.tmpl`
- **AND** renders it with merged YAML data (orchestrator-specific config + hosts)
- **AND** the template filters hosts by role (e.g., role == "k8s-master")
- **AND** generates INI-formatted inventory with [all], [kube_control_plane], [etcd], [kube_node] sections
- **AND** outputs `kubespray/inventory.ini` that Kubespray Docker container expects at mount point

#### Scenario: Output structure consistency
- **WHEN** platform changes from Proxmox to AWS in master config
- **THEN** the API CLI generates `api/outputs/<env>/terraform.tfvars` with different content but same semantic structure
- **AND** downstream modules (infrastructure/deploy.sh) consume outputs identically
- **AND** input variables differ by platform, but output contract remains consistent

#### Scenario: Template syntax error handling
- **WHEN** a template has invalid Go template syntax
- **THEN** the API CLI reports the syntax error with template path, file name, and line number during rendering
- **AND** exits with non-zero status to prevent generating invalid outputs
```

**Rationale**: Platform/orchestrator-organized templates enable multi-platform support without code changes, single source of truth format (YAML), centralized format logic per platform, easier validation and transformation, consistent engineer workflow regardless of deployment target, maintains output contract consistency across platforms.

---

## MODIFIED Requirement: Infrastructure Platform Abstraction (MVP)

### Before

```markdown
### Requirement: Infrastructure Platform Abstraction (MVP)
The `infrastructure/` module SHALL organize assets into `environments/` and `platforms/<platform>/<provider>/`. The MVP MUST relocate the existing Proxmox/Terraform implementation to `platforms/proxmox/terraform/` and ensure it reads environment + role data from the `api/` outputs and the referenced config package. Slots for `baremetal/libvirt` and `cloud/{aws,gcp,azure}` SHALL exist, even if empty.

#### Scenario: Terraform uses API artifacts
- **WHEN** the Proxmox Terraform code runs from `infrastructure/platforms/proxmox/terraform`
- **THEN** it reads host definitions, networking, and credentials from the API-generated files and config package (rather than private bootstrap directories)
- **AND** engineers can point configs in `infrastructure/environments/` at other platforms once they exist.
```

### After

```markdown
### Requirement: Infrastructure Platform Abstraction (MVP)
The `infrastructure/` module SHALL organize assets into `environments/` and `platforms/<platform>/<provider>/`. The MVP MUST relocate the existing Proxmox/Terraform implementation to `platforms/proxmox/terraform/` and ensure it reads environment + role data from `api/outputs/<env>/terraform.tfvars` generated via Go templates from YAML configs. Module environment files (`infrastructure/environments/<env>.yaml`) SHALL reference a config package and provide overrides (secrets, env-specific IPs). Slots for `baremetal/libvirt` and `cloud/{aws,gcp,azure}` SHALL exist, even if empty.

#### Scenario: Terraform uses generated tfvars
- **WHEN** the Proxmox Terraform code runs from `infrastructure/platforms/proxmox/terraform`
- **THEN** the deployment script stages `api/outputs/development/terraform.tfvars` (generated from YAML) to the Terraform module directory
- **AND** Terraform reads all host definitions, networking, and credentials from the generated .tfvars file
- **AND** engineers modify infrastructure by editing YAML in `config/packages/infrastructure/` and `infrastructure/environments/development.yaml`, then regenerating with the API CLI

#### Scenario: Environment-specific credentials
- **WHEN** deploying to production
- **THEN** `infrastructure/environments/production.yaml` contains production Proxmox API tokens and SSH keys (gitignored or encrypted)
- **AND** the API merges these with base configs from `config/packages/infrastructure/` and generates `api/outputs/production/terraform.tfvars`
- **AND** no production secrets exist in the git-tracked config package
```

**Rationale**: Clarifies that Terraform consumes generated files, not raw config packages. Emphasizes YAML workflow and secret separation.

---

## MODIFIED Requirement: Container-Orchestration Provider Interface (MVP)

### Before

```markdown
### Requirement: Container-Orchestration Provider Interface (MVP)
The `container-orchestration/` module MUST expose a provider interface where each provider resides under `providers/<name>/` with standardized `deploy/reset/validate` entrypoints and documentation. The current Kubespray flow SHALL live under `providers/kubespray/` and consume inventories/vars from the API outputs. Stubs for `kubekey` and `kind` SHALL be present for future work.

#### Scenario: Kubespray deploy uses provider contract
- **WHEN** an engineer runs `container-orchestration/providers/kubespray/deploy.sh --env development`
- **THEN** the script loads the API-generated inventory, runs Kubespray from within its provider directory, and records status via the shared interface so platform automation does not call bespoke scripts.
```

### After

```markdown
### Requirement: Container-Orchestration Provider Interface (MVP)
The `container-orchestration/` module MUST expose a provider interface where each provider resides under `providers/<name>/` with standardized `deploy/reset/validate` entrypoints and documentation. The Kubespray provider SHALL consume inventories from `api/outputs/<env>/kubespray/` which are generated via Go templates transforming YAML configs into INI format and group_vars YAML. Docker volume mounting requirements SHALL be explicitly documented in the provider README. Module environment files (`container-orchestration/environments/<env>.yaml`) SHALL provide overrides like SSH key paths and Docker image versions. Stubs for `kubekey` and `kind` SHALL be present for future work.

#### Scenario: Kubespray deploy with generated inventory
- **WHEN** an engineer runs `container-orchestration/providers/kubespray/deploy.sh --env development`
- **THEN** the script:
  1. Reads `api/outputs/development/metadata.json` to find inventory path
  2. Stages `api/outputs/development/kubespray/inventory.ini` (generated from YAML) and group_vars to `providers/kubespray/inventory/current/`
  3. Mounts staged inventory to Docker container at `/kubespray/inventory/runtime/`
  4. Mounts SSH key (path from `container-orchestration/environments/development.yaml`) to container at `/root/.ssh/id_rsa`
  5. Runs Kubespray Ansible playbooks inside container
- **AND** the provider README documents exact Docker mount requirements

#### Scenario: Environment-specific Kubespray settings
- **WHEN** deploying to staging with a different Kubespray version
- **THEN** `container-orchestration/environments/staging.yaml` specifies `docker.image: "quay.io/kubespray/kubespray:v2.29.0"`
- **AND** the deploy script uses this image version instead of the default
```

**Rationale**: Clarifies generated inventory format, documents Docker mounting requirements, adds environment override support for provider settings.

---

## Summary of Changes

| Aspect | Before | After |
|--------|--------|-------|
| **Config Location** | `api/definitions/` | `config/packages/core/` (master config pattern) |
| **Config Organization** | Monolithic | Platform-agnostic (root) + platform-specific (`platforms/`) + orchestrator-specific (`orchestrators/`) |
| **Platform/Orchestrator Choice** | Hardcoded in code | Declared in master config (`config.yaml`) |
| **Config Format** | Mixed (.tfvars, .json, .yaml, .ini) | YAML only (all inputs) |
| **Template Organization** | Single path per module | Organized by platform/provider/orchestrator |
| **Template Selection** | Manual/hardcoded | Automatic based on master config |
| **Multi-Platform Support** | Requires code changes | Config-driven, no code changes |
| **Env Overrides** | Informal, unvalidated | Formal schemas in `api/schemas/environments/` |
| **Output Generation** | Direct copy | Go `text/template` rendering with platform-specific templates |
| **Output Structure** | Platform-dependent | Consistent contract across all platforms |
| **Secret Management** | Implicit | Explicit separation (env files, gitignored) |
| **Module Contracts** | Undocumented | Requirements + Outputs in READMEs |

These changes enforce clean architectural boundaries, enable multi-platform support without code changes, improve validation, simplify configuration authoring, formalize secret management practices, and maintain consistent output contracts across deployment targets.
