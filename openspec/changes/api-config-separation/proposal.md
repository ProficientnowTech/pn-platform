## Why

The current architecture violates separation of concerns by storing configuration data (`api/definitions/`) alongside validation schemas (`api/schemas/`) within the API module. The API module acts as both a tool (validation/generation) and a data store (definitions), which creates several problems:

1. **Tight Coupling**: Configuration data is intermingled with validation logic, making it difficult to version configs independently from the API tool itself.
2. **Mixed Formats**: Config packages contain multiple formats (.tfvars, .json, .yaml, .ini) directly, requiring the API to handle format-specific logic instead of using a unified input format.
3. **No Environment Override Schema**: Module-specific environment files (containing secrets and overrides) lack formal schemas, leading to inconsistent validation across modules.
4. **Unclear Module Contracts**: Modules lack documented Requirements and Outputs sections, making it difficult to understand dependencies and integration points.
5. **Template Absence**: The API currently copies config files directly rather than using Go templates to transform YAML configs into module-native formats, missing an opportunity for validation and transformation.

These issues block clean module boundaries, complicate secret management (since sensitive data can't live in git-tracked config packages), and make it harder to onboard new infrastructure providers or orchestration systems.

## What Changes

### 1. Separate API (Tool) from Config (Data)
- **Move** `api/definitions/` → `config/packages/core/` as a master configuration package that declares platform/provider/orchestrator choices
- **API module** becomes a pure tool that holds only schemas, templates, and generation/validation logic
- **Config module** becomes the source of truth for all non-sensitive base configuration data
- **Master config** (`config/packages/core/config.yaml`) declares infrastructure platform (Proxmox, AWS, GCP, Azure, bare metal), provider (Terraform, Pulumi), and orchestrator (Kubespray, Kubekey, Kind) selections
- **Platform-specific configs** stored under `config/packages/core/platforms/` and `config/packages/core/orchestrators/` to support multiple deployment targets
- **Templates** organized by platform/provider/orchestrator choice to handle varying input variables while maintaining consistent output contract

### 2. Enforce YAML-Only Inputs
- **All base configs** in `config/packages/core/` must be YAML format (platform-agnostic and platform-specific)
- **All environment overrides** in `<module>/environments/<env>.yaml` must be YAML format
- **API generates** module-native formats (.tfvars, .json, .ini) from YAML using Go `text/template`
- **Templates** selected based on master config choices (e.g., `api/templates/infrastructure/proxmox/terraform/` vs `api/templates/infrastructure/aws/terraform/`)

### 3. Add Environment Override Schemas
- **Create** `api/schemas/environments/<module>.schema.yaml` for each module
- **Validate** all `<module>/environments/<env>.yaml` files against these schemas
- **Document** what can be overridden per module (secrets, env-specific settings)

### 4. Implement Go Template Pipeline
- **Create** `api/templates/` organized by platform/provider/orchestrator choice
- **Templates** transform merged YAML configs into module-native formats:
  - `infrastructure/{platform}/{provider}/terraform.tfvars.tmpl` → generates HCL for Terraform (Proxmox, AWS, GCP, etc.)
  - `provisioner/config.json.tmpl` → generates JSON for provisioner
  - `container-orchestration/{orchestrator}/inventory.ini.tmpl` → generates INI for Kubespray
  - `container-orchestration/{orchestrator}/config.yaml.tmpl` → generates YAML for Kubekey/Kind
  - `platform/values.yaml.tmpl` → generates Helm values for platform
  - `business/values.yaml.tmpl` → generates Helm values for business
- **API CLI** reads master config to select appropriate template paths based on user's platform/provider/orchestrator choices

### 5. Document Module Contracts
- **Add Requirements section** to each module README: inputs, formats, folder structure, env vars
- **Add Outputs section** to each module README: what it generates, formats, locations
- **Document critical patterns**: Docker mounting (Kubespray), secrets handling (Platform)

### 6. Refactor API CLI Commands
- **`generate env`**: Load base YAML configs → merge with env YAML overrides → validate → render templates → write native formats
- **`validate`**: Add `--target environments` to validate environment override files against schemas

## Impact

### Specs
- **Updates** `repository-modular-architecture` spec to clarify API/Config separation and YAML-only input requirement
- **Adds** environment schema requirement for each module

### Code
- **Relocates** `api/definitions/` → `config/packages/core/` with master config pattern
- **Organizes** config by platform/orchestrator choice under `config/packages/core/platforms/` and `config/packages/core/orchestrators/`
- **Creates** `api/schemas/environments/` with 5 new schemas
- **Creates** `api/templates/` organized by platform/provider/orchestrator with templates for multiple deployment targets
- **Updates** API CLI generation logic to:
  - Read master config to determine platform/provider/orchestrator selections
  - Load platform-agnostic configs (hosts, networks) and platform-specific configs
  - Select appropriate templates based on choices
  - Support template rendering and config merging
  - Generate consistent output structure regardless of platform choice
- **Updates** all module READMEs with Requirements and Outputs sections

### Tooling/Workflows
- Engineers create/edit YAML configs only (never touch .tfvars, .json, .ini directly)
- Secrets stored in `<module>/environments/<env>.yaml` (excluded from git or encrypted)
- Config packages remain version-controlled in git (no secrets)
- API CLI orchestrates: validate → merge → template → generate
- Module deployment scripts unchanged (still consume `api/outputs/<env>/`)

### Migration
- **Backward compatibility**: Temporary shims allow existing workflows to continue during transition
- **Validation**: End-to-end deployment test verifies all modules work with new architecture
- **Documentation**: Migration guide in `docs/migration/` explains config package restructuring
