## Context

The repository currently mixes tool logic (schemas, validators, generators) with configuration data (definitions, environment values) inside the API module. Config packages in `config/packages/core/` contain pre-rendered files in multiple native formats (.tfvars, .json, .ini, .yaml), which prevents a clean separation between reusable base configuration and environment-specific overrides (especially secrets). Module environment files lack schemas, making validation inconsistent. Module READMEs don't document inputs/outputs, making integration brittle.

We need an architecture where:
1. API is a pure tool (schemas + templates + CLI)
2. Config holds base data only (YAML format, git-tracked, no secrets)
3. Module environments hold overrides (YAML format, secrets, not in git)
4. API generates module-native formats from YAML using Go templates
5. Module contracts are explicitly documented

## Goals

- **Separate data from tooling**: Move all configuration definitions out of `api/` into `config/packages/<module>/`
- **Enforce YAML-only inputs**: All base configs and environment overrides must be YAML; native formats are generated
- **Add environment schemas**: Create `api/schemas/environments/<module>.schema.yaml` to validate module-specific overrides
- **Implement template pipeline**: Use Go `text/template` to transform YAML → native formats
- **Document module contracts**: Add Requirements and Outputs sections to all module READMEs
- **Preserve secret management**: Sensitive data lives in `<module>/environments/` (gitignored or encrypted), never in config packages

## Non-Goals

- Changing module deployment scripts or workflows (they still consume `api/outputs/<env>/`)
- Adding new infrastructure providers or orchestrators (this is purely architectural)
- Implementing secret encryption/sealing (existing sealed-secrets mechanism remains)
- Changing config package versioning strategy (still uses package.json + Git releases)

## Decisions

### 1. API Module Becomes Pure Tool

**Decision**: `api/` holds only schemas, templates, and CLI logic. No configuration data.

**Structure**:
```
api/
├── bin/api                          # Compiled CLI binary
├── cmd/api/                         # CLI entrypoint
├── internal/
│   ├── commands/                    # validate, generate, provision
│   ├── generators/                  # Template rendering logic
│   ├── validators/                  # Schema validation
│   └── merger/                      # Config merging (base + overrides)
├── schemas/
│   ├── hosts.schema.yaml
│   ├── networks.schema.yaml
│   ├── roles.schema.yaml
│   └── environments/                # NEW: Environment override schemas
│       ├── infrastructure.schema.yaml
│       ├── provisioner.schema.yaml
│       ├── kubespray.schema.yaml
│       ├── platform.schema.yaml
│       └── business.schema.yaml
├── templates/                       # NEW: Go text/template files
│   ├── infrastructure/
│   │   └── terraform.tfvars.tmpl
│   ├── provisioner/
│   │   └── config.json.tmpl
│   ├── kubespray/
│   │   ├── inventory.ini.tmpl
│   │   └── group_vars.yaml.tmpl
│   ├── platform/
│   │   └── values.yaml.tmpl
│   └── business/
│       └── values.yaml.tmpl
└── outputs/                         # Generated files (gitignored)
    └── <env>/
        ├── metadata.json
        ├── terraform.tfvars         # HCL format (from template)
        ├── provisioner.json         # JSON format (from template)
        ├── kubespray/
        │   ├── inventory.ini        # INI format (from template)
        │   └── group_vars/
        │       └── all.yaml         # YAML format (from template)
        ├── platform.yaml            # YAML format (from template)
        └── business.yaml            # YAML format (from template)
```

**Rationale**: Clear separation of concerns. API is a versioned tool distributed via GitHub releases. Configuration data has its own lifecycle.

### 2. Config Module with Master Config Pattern

**Decision**: Move `api/definitions/` → `config/packages/core/` as a master configuration package that declares platform/provider/orchestrator choices. Support multiple deployment targets (Proxmox, AWS, GCP, Kubespray, Kubekey, etc.) through organized platform-specific configs.

**Structure**:
```
config/
├── validate.sh                      # Config manifest validator
└── packages/
    └── core/
        ├── package.json             # Master package manifest
        ├── README.md
        ├── config.yaml              # MASTER: Declares platform/provider/orchestrator choices
        ├── hosts.yaml               # Platform-agnostic host definitions
        ├── networks.yaml            # Platform-agnostic network configs
        ├── platforms/               # Platform-specific settings
        │   ├── proxmox.yaml         # Proxmox-specific (endpoint, node_name, datastore)
        │   ├── aws.yaml             # AWS-specific (region, vpc_id, instance_type)
        │   ├── gcp.yaml             # GCP-specific
        │   ├── azure.yaml           # Azure-specific
        │   └── baremetal-libvirt.yaml  # Bare metal + libvirt settings
        ├── orchestrators/           # Orchestrator-specific settings
        │   ├── kubespray.yaml       # Kubespray-specific (cluster config)
        │   ├── kubekey.yaml         # Kubekey-specific
        │   └── kind.yaml            # Kind-specific
        ├── platform/
        │   └── stacks.yaml          # Platform services config
        └── business/
            └── apps.yaml            # Business apps config
```

**Master Config** (`config.yaml`):
```yaml
# Master configuration declaring choices
version: v1.0.0

infrastructure:
  platform: proxmox        # Options: proxmox, aws, gcp, azure, baremetal
  provider: terraform      # Options: terraform, pulumi, ansible

container_orchestration:
  orchestrator: kubespray  # Options: kubespray, kubekey, kind
  provider: docker         # Options: docker, podman, native

platform:
  enabled: true

business:
  enabled: true
```

**Platform-Specific Config Example** (`platforms/proxmox.yaml`):
```yaml
# Proxmox-specific settings (non-sensitive)
endpoint: "https://proxmox.example.com:8006/api2/json"
node_name: "pve-node-01"
datastore: "local-lvm"
# Note: api_token comes from environment override (secret)
```

**Platform-Specific Config Example** (`platforms/aws.yaml`):
```yaml
# AWS-specific settings (non-sensitive)
region: us-east-1
vpc_id: vpc-abc123
subnet_ids:
  - subnet-xyz789
instance_type: t3.medium
# Note: access_key, secret_key come from environment override (secrets)
```

**Package Manifest** (`package.json`):
```json
{
  "id": "core",
  "version": "v1.0.0",
  "description": "Master configuration with platform/orchestrator choices",
  "files": [
    "config.yaml",
    "hosts.yaml",
    "networks.yaml",
    "platforms/*.yaml",
    "orchestrators/*.yaml",
    "platform/stacks.yaml",
    "business/apps.yaml"
  ]
}
```

**Rationale**:
- Single master config package provides unified versioning
- Platform/orchestrator choices declared explicitly in `config.yaml`
- Platform-specific configs isolated under `platforms/` and `orchestrators/`
- Supports multiple deployment targets without code changes
- Input variables differ by choice, but output contract remains consistent
- API CLI selects appropriate templates based on master config selections

### 3. Module Environments for Overrides

**Decision**: Each module has `environments/<env>.yaml` for secrets and environment-specific overrides.

**Location**: `<module>/environments/<env>.yaml`

**Examples**:

**infrastructure/environments/development.yaml**:
```yaml
configPackage: core
environment: development

# Sensitive Proxmox credentials (for selected platform)
proxmox:
  api_token: "root@pam!dev-token=xxxxxxxx"
  # Can override endpoint if different from base config
  endpoint: "https://192.168.1.100:8006/api2/json"

# Environment-specific SSH key
ssh:
  private_key_path: "/home/user/.ssh/id_ed25519"
  public_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."

# Override specific hosts for development
hosts_override:
  - name: k8s-master-01
    ip: 192.168.106.10  # Dev network
```

**container-orchestration/environments/development.yaml**:
```yaml
configPackage: core
environment: development

# Override Kubespray image version for dev
kubespray:
  docker_image: "quay.io/kubespray/kubespray:v2.28.1"

# SSH settings for cluster nodes
ssh:
  key_path: "/home/user/.ssh/id_ed25519"
  user: "ansible"
  port: 22
```

**platform/environments/development.yaml**:
```yaml
configPackage: core
environment: development

# ArgoCD admin password
argocd:
  admin_password: "dev@Supreme2354"

# Sealed secrets public key
sealed_secrets:
  public_key_path: "/path/to/sealed-secrets-pub.pem"

# Override stack enablement for dev
stacks:
  base:
    enabled: true
  monitoring:
    enabled: false
  ml:
    enabled: false

# Secret specs environment variables
secrets:
  GRAFANA_ADMIN_PASSWORD: "admin123"
  VAULT_ROOT_TOKEN: "root-token-dev"
```

**Rationale**: Separates secrets from base config. Environment files are gitignored or encrypted (sealed-secrets, SOPS, etc.). Validated against environment schemas.

### 4. YAML-Only Inputs, Native Format Outputs with Template Selection

**Decision**: All configuration inputs are YAML. API generates module-native formats using Go templates organized by platform/provider/orchestrator choice.

**Template Organization**:
```
api/templates/
├── infrastructure/
│   ├── proxmox/
│   │   └── terraform/
│   │       └── terraform.tfvars.tmpl
│   ├── aws/
│   │   └── terraform/
│   │       └── terraform.tfvars.tmpl
│   ├── gcp/
│   │   └── terraform/
│   │       └── terraform.tfvars.tmpl
│   ├── azure/
│   │   └── terraform/
│   │       └── terraform.tfvars.tmpl
│   └── baremetal/
│       └── libvirt/
│           └── terraform.tfvars.tmpl
├── provisioner/
│   └── config.json.tmpl
├── container-orchestration/
│   ├── kubespray/
│   │   ├── inventory.ini.tmpl
│   │   └── group_vars.yaml.tmpl
│   ├── kubekey/
│   │   └── config.yaml.tmpl
│   └── kind/
│       └── config.yaml.tmpl
├── platform/
│   └── values.yaml.tmpl
└── business/
    └── values.yaml.tmpl
```

**Input Flow with Template Selection**:
```
1. Read Master Config (config/packages/core/config.yaml)
   ↓
2. Determine selections:
   - infrastructure.platform = "proxmox"
   - infrastructure.provider = "terraform"
   - container_orchestration.orchestrator = "kubespray"
   ↓
3. Load Base Configs (YAML):
   - config/packages/core/hosts.yaml (platform-agnostic)
   - config/packages/core/networks.yaml (platform-agnostic)
   - config/packages/core/platforms/proxmox.yaml (platform-specific)
   - config/packages/core/orchestrators/kubespray.yaml (orchestrator-specific)
   ↓
4. Load Environment Overrides (YAML):
   - infrastructure/environments/development.yaml (secrets, overrides)
   - container-orchestration/environments/development.yaml (secrets, overrides)
   ↓
5. Merge: Base + Overrides = Merged YAML Data
   ↓
6. Select Templates Based on Master Config:
   - api/templates/infrastructure/proxmox/terraform/terraform.tfvars.tmpl
   - api/templates/container-orchestration/kubespray/inventory.ini.tmpl
   ↓
7. Render Templates with Merged Data
   ↓
8. Generate Outputs (Native Formats):
   - api/outputs/development/terraform.tfvars (HCL)
   - api/outputs/development/kubespray/inventory.ini (INI)
   - api/outputs/development/kubespray/group_vars/all.yaml (YAML)
   - api/outputs/development/platform.yaml (Helm)
```

**Template Example** (`api/templates/infrastructure/proxmox/terraform/terraform.tfvars.tmpl`):
```hcl
# Generated from YAML config via API

global_config = {
  environment     = "{{.Environment}}"
  resource_prefix = "{{.ResourcePrefix}}"

  proxmox_config = {
    endpoint  = "{{.Proxmox.Endpoint}}"
    api_token = "{{.Proxmox.APIToken}}"
    node_name = "{{.Proxmox.NodeName}}"
    datastore = "{{.Proxmox.Datastore}}"
  }
}

networking = {
  vlan_range_start = {{.Networking.VLANRangeStart}}
  vlan_range_end   = {{.Networking.VLANRangeEnd}}
  gateway          = "{{.Networking.Gateway}}"
  dns_servers      = [{{range $i, $dns := .Networking.DNSServers}}{{if $i}},{{end}}"{{$dns}}"{{end}}]
}

{{range .Hosts}}
host_{{.Name}} = {
  ip     = "{{.IP}}"
  role   = "{{.Role}}"
  cpu    = {{.CPU}}
  memory = {{.Memory}}
}
{{end}}
```

**Template Example** (`api/templates/kubespray/inventory.ini.tmpl`):
```ini
# Generated from YAML config via API

[all]
{{range .Hosts}}
{{.Name}} ansible_host={{.IP}} ip={{.IP}}
{{end}}

[kube_control_plane]
{{range .Hosts}}{{if eq .Role "k8s-master"}}
{{.Name}}
{{end}}{{end}}

[etcd]
{{range .Hosts}}{{if eq .Role "k8s-master"}}
{{.Name}}
{{end}}{{end}}

[kube_node]
{{range .Hosts}}{{if or (eq .Role "k8s-master") (eq .Role "k8s-worker")}}
{{.Name}}
{{end}}{{end}}
```

**Rationale**: Single source of truth format (YAML) makes validation and merging straightforward. Templates handle format-specific syntax. Engineers never hand-edit .tfvars or .ini files.

### 5. Environment Override Schemas

**Decision**: Create `api/schemas/environments/<module>.schema.yaml` to validate environment-specific overrides.

**Example** (`api/schemas/environments/infrastructure.schema.yaml`):
```yaml
$schema: http://json-schema.org/draft-07/schema#
title: Infrastructure Environment Configuration
type: object
required:
  - configPackage
  - environment
properties:
  configPackage:
    type: string
    description: Reference to config package ID
  environment:
    type: string
    enum: [development, staging, production]
  proxmox:
    type: object
    required: [api_token, endpoint, node_name]
    properties:
      api_token:
        type: string
        pattern: '^[^@]+@[^!]+![^=]+=.+'
      endpoint:
        type: string
        format: uri
      node_name:
        type: string
      datastore:
        type: string
        default: local-lvm
  ssh:
    type: object
    properties:
      private_key_path:
        type: string
      public_key:
        type: string
  hosts_override:
    type: array
    items:
      type: object
      required: [name, ip]
      properties:
        name:
          type: string
        ip:
          type: string
          format: ipv4
```

**Example** (`api/schemas/environments/platform.schema.yaml`):
```yaml
$schema: http://json-schema.org/draft-07/schema#
title: Platform Environment Configuration
type: object
required:
  - configPackage
  - environment
properties:
  configPackage:
    type: string
  environment:
    type: string
  argocd:
    type: object
    properties:
      admin_password:
        type: string
        minLength: 8
  sealed_secrets:
    type: object
    properties:
      public_key_path:
        type: string
  stacks:
    type: object
    properties:
      base:
        type: object
        properties:
          enabled:
            type: boolean
      monitoring:
        type: object
        properties:
          enabled:
            type: boolean
      ml:
        type: object
        properties:
          enabled:
            type: boolean
  secrets:
    type: object
    description: Environment variables for secret specs
    additionalProperties:
      type: string
```

**Rationale**: Formalizes what can be overridden per module. Enables consistent validation. Documents contract between base config and environment-specific data.

### 6. Module Contract Documentation

**Decision**: Add Requirements and Outputs sections to all module READMEs.

**Template**:
```markdown
# [Module Name]

## Overview
Brief description of module purpose.

## Requirements

### Input Files
- **Config Package**: `config/packages/<module>/`
  - `file1.yaml` - Description
  - `file2.yaml` - Description
- **Environment Override**: `<module>/environments/<env>.yaml`
  - Must contain: field1, field2
  - Optional: field3, field4
  - Schema: `api/schemas/environments/<module>.schema.yaml`

### Environment Variables
- `VAR1` - Description (required)
- `VAR2` - Description (optional, default: value)

### Folder Structure
```
expected/
├── directory/
│   └── structure/
```

### External Dependencies
- Tool1 (version)
- Tool2 (version)

### Docker Mounting (if applicable)
```bash
--mount type=bind,source="<host-path>",dst="<container-path>"
```

## Outputs

### Generated Files
- `output/path/file1` - Format, description
- `output/path/file2` - Format, description

### Downstream Consumption
- Module X consumes: file1 for purpose Y
- Module Z consumes: file2 for purpose W

## Integration Points
- Depends on: Module A, Module B
- Consumed by: Module C, Module D
```

**Rationale**: Explicit documentation enables safe integration, makes onboarding easier, and serves as contract for schema creation.

### 7. API CLI Refactoring

**Decision**: Update `api generate env` to read master config, select templates based on platform/orchestrator choices, load configs, merge, validate, and render.

**Pseudocode**:
```go
func GenerateEnvironment(envID, configPkg string) error {
    // 1. Load master config to determine choices
    masterConfig := loadMasterConfig(configPkg + "/config.yaml")
    platform := masterConfig.Infrastructure.Platform           // e.g., "proxmox"
    provider := masterConfig.Infrastructure.Provider           // e.g., "terraform"
    orchestrator := masterConfig.ContainerOrchestration.Orchestrator  // e.g., "kubespray"

    // 2. Load platform-agnostic base configs
    baseConfigs := make(map[string]interface{})
    baseConfigs["hosts"] = loadYAML(configPkg + "/hosts.yaml")
    baseConfigs["networks"] = loadYAML(configPkg + "/networks.yaml")

    // 3. Load platform-specific configs based on selections
    baseConfigs["platform_specific"] = loadYAML(
        configPkg + "/platforms/" + platform + ".yaml",
    )
    baseConfigs["orchestrator_specific"] = loadYAML(
        configPkg + "/orchestrators/" + orchestrator + ".yaml",
    )
    baseConfigs["platform_stacks"] = loadYAML(configPkg + "/platform/stacks.yaml")
    baseConfigs["business_apps"] = loadYAML(configPkg + "/business/apps.yaml")

    // 4. Load environment overrides from each module
    envOverrides := loadModuleEnvironments(envID)

    // 5. Validate environment files against schemas
    validateEnvironments(envOverrides, "api/schemas/environments/")

    // 6. Merge base + overrides
    merged := mergeConfigs(baseConfigs, envOverrides)

    // 7. Validate merged configs against general schemas
    validateMerged(merged, "api/schemas/")

    // 8. Select templates based on platform/orchestrator
    templatePaths := make(map[string]string)
    templatePaths["infrastructure"] = fmt.Sprintf(
        "api/templates/infrastructure/%s/%s/terraform.tfvars.tmpl",
        platform, provider,
    )
    templatePaths["orchestrator_inventory"] = fmt.Sprintf(
        "api/templates/container-orchestration/%s/inventory.ini.tmpl",
        orchestrator,
    )
    templatePaths["orchestrator_groupvars"] = fmt.Sprintf(
        "api/templates/container-orchestration/%s/group_vars.yaml.tmpl",
        orchestrator,
    )
    templatePaths["provisioner"] = "api/templates/provisioner/config.json.tmpl"
    templatePaths["platform"] = "api/templates/platform/values.yaml.tmpl"
    templatePaths["business"] = "api/templates/business/values.yaml.tmpl"

    // 9. Render templates with merged data
    outputs := make(map[string]string)
    outputs["terraform.tfvars"] = renderTemplate(
        templatePaths["infrastructure"],
        merged,
    )
    outputs["provisioner.json"] = renderTemplate(
        templatePaths["provisioner"],
        merged,
    )
    outputs["orchestrator/inventory.ini"] = renderTemplate(
        templatePaths["orchestrator_inventory"],
        merged,
    )
    outputs["orchestrator/group_vars/all.yaml"] = renderTemplate(
        templatePaths["orchestrator_groupvars"],
        merged,
    )
    outputs["platform.yaml"] = renderTemplate(
        templatePaths["platform"],
        merged,
    )
    outputs["business.yaml"] = renderTemplate(
        templatePaths["business"],
        merged,
    )

    // 10. Write outputs with consistent structure
    writeOutputs(envID, outputs)

    // 11. Generate metadata.json with all paths
    writeMetadata(envID, outputs, masterConfig)

    return nil
}
```

**Rationale**:
- Master config drives template selection, enabling multi-platform support without code changes
- Input variables differ by platform/orchestrator choice
- Output structure remains consistent regardless of selections
- Single command orchestrates entire pipeline: read choices → load → merge → validate → select templates → render → write

## Migration Plan

### Phase 1: Documentation (Week 1)
1. Update all module READMEs with Requirements and Outputs sections
2. Document Kubespray Docker mounting requirements
3. Document Platform secrets handling
4. Create migration guide in `docs/migration/api-config-separation.md`

### Phase 2: Schemas (Week 1-2)
1. Create `api/schemas/environments/` directory
2. Write environment schema for each module (5 schemas)
3. Add validation tests for environment schemas

### Phase 3: Config Restructure (Week 2)
1. Create `config/packages/core/` directory with subdirectories (`platforms/`, `orchestrators/`, `platform/`, `business/`)
2. Move and convert `api/definitions/` → YAML format in new locations
3. Create master config (`config/packages/core/config.yaml`) declaring platform/provider/orchestrator choices
4. Organize platform-agnostic configs (hosts.yaml, networks.yaml) at package root
5. Create platform-specific configs under `platforms/` (proxmox.yaml, aws.yaml, etc.)
6. Create orchestrator-specific configs under `orchestrators/` (kubespray.yaml, kubekey.yaml, kind.yaml)
7. Update package.json manifest to reference all files
8. Add README to config package explaining master config pattern

### Phase 4: Templates (Week 2-3)
1. Create `api/templates/` directory organized by platform/provider/orchestrator
2. Create infrastructure templates:
   - `infrastructure/proxmox/terraform/terraform.tfvars.tmpl`
   - `infrastructure/aws/terraform/terraform.tfvars.tmpl` (stub for future)
   - `infrastructure/gcp/terraform/terraform.tfvars.tmpl` (stub for future)
   - `infrastructure/baremetal/libvirt/terraform.tfvars.tmpl` (stub for future)
3. Create container-orchestration templates:
   - `container-orchestration/kubespray/inventory.ini.tmpl`
   - `container-orchestration/kubespray/group_vars.yaml.tmpl`
   - `container-orchestration/kubekey/config.yaml.tmpl` (stub for future)
   - `container-orchestration/kind/config.yaml.tmpl` (stub for future)
4. Create provisioner, platform, business templates:
   - `provisioner/config.json.tmpl`
   - `platform/values.yaml.tmpl`
   - `business/values.yaml.tmpl`
5. Test templates against sample data for each platform/orchestrator combination
6. Validate generated outputs match current formats and requirements

### Phase 5: API CLI (Week 3-4)
1. Implement master config reader to load and parse `config/packages/core/config.yaml`
2. Implement platform/orchestrator selection logic based on master config
3. Implement template path resolver (platform + provider + orchestrator → template paths)
4. Implement config merger (base platform-agnostic + platform-specific + overrides)
5. Add environment validation to `api validate` command with `--target environments` flag
6. Update `api generate env` to:
   - Read master config
   - Select appropriate templates
   - Load platform-agnostic and platform-specific configs
   - Merge with environment overrides
   - Render selected templates
   - Generate consistent output structure
7. Add integration tests covering multiple platform/orchestrator combinations

### Phase 6: Module Environments (Week 4)
1. Create `<module>/environments/` directories
2. Extract secrets from config packages → environment files
3. Add .gitignore entries or encryption setup
4. Test environment validation

### Phase 7: Integration Testing (Week 5)
1. End-to-end deployment test with new architecture
2. Verify all modules consume generated outputs correctly
3. Test Kubespray Docker mounting with new inventory format
4. Test Platform secrets with new env var mechanism
5. Document results in `docs/validation.md`

### Phase 8: Cleanup (Week 5)
1. Remove `api/definitions/` after migration confirmed
2. Update CI/CD pipelines if needed
3. Archive old documentation
4. Tag release with new architecture

## Alternatives Considered

### Alternative 1: Keep Mixed Formats in Config
**Rejected**: Would preserve complexity of handling multiple formats. YAML-only input with template generation is cleaner.

### Alternative 2: Single Monolithic Config Package
**Rejected**: Module-specific packages enable independent versioning and clearer boundaries.

### Alternative 3: Use Jsonnet/CUE Instead of Go Templates
**Rejected**: Go templates are native to the ecosystem (Helm, Terraform use similar), require no additional dependencies, and team is already familiar.

### Alternative 4: Environment Files in Config Packages
**Rejected**: Secrets should never be in git-tracked config packages. Separate `<module>/environments/` with gitignore/encryption is safer.

## Risks / Trade-offs

### Risk: Template Syntax Errors
**Mitigation**: Comprehensive template tests with sample data. Schema validation before rendering.

### Risk: Migration Complexity
**Mitigation**: Phased approach with backward compatibility shims. Extensive testing at each phase.

### Risk: Team Learning Curve
**Mitigation**: Updated documentation, migration guide, examples. YAML is simpler than learning multiple formats.

### Risk: Config Package Versioning
**Mitigation**: Maintain package.json manifests. Clear upgrade documentation. Breaking changes follow semver.

### Trade-off: Initial Setup Overhead
Templates and schemas require upfront work, but pay dividends in consistency and safety over time.

### Trade-off: Template Maintenance
Changes to output formats require template updates, but this is centralized and testable vs scattered format logic.

## Open Questions

1. **Should we support multiple config package versions simultaneously?**
   → Answer: Not initially. Environment references single package version. Upgrade path documented.

2. **How do we handle Kubespray inventory.ini generation given complex host groups?**
   → Answer: Template logic handles conditionals (`if eq .Role "k8s-master"`). Sample tested before rollout.

3. **Do environment files support includes/references?**
   → Answer: Not in MVP. Keep simple. Advanced features can be added later if needed.

4. **Should we encrypt environment files or rely on gitignore?**
   → Answer: Gitignore for development. Production uses sealed-secrets/SOPS. Document both approaches.

5. **How do we version environment schemas alongside API?**
   → Answer: Schemas live in API module, versioned with API releases. Breaking changes require major version bump.
