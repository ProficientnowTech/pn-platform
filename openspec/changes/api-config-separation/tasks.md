## Phase 1: Module Contract Documentation

### 1.1 Document Infrastructure Module
- [ ] Add Requirements section to `infrastructure/README.md`
  - Input files from config package (hosts.yaml, networks.yaml, proxmox.yaml)
  - Environment override schema requirements
  - Environment variables (PROXMOX_API_TOKEN, SSH_KEY_PATH, etc.)
  - Terraform version requirements
- [ ] Add Outputs section to `infrastructure/README.md`
  - Terraform state files location
  - VM IPs, hostnames, resource IDs
  - Network configuration exports
  - SSH key outputs
- [ ] Document Terraform variable staging mechanism
- [ ] Document deployment phases (bootstrap, images, templates, nodes, ansible)

### 1.2 Document Provisioner Module
- [ ] Add Requirements section to `provisioner/README.md`
  - Input: provisioner.json from API
  - Role definitions structure
  - Ansible requirements
  - Environment variables for builds
- [ ] Add Outputs section to `provisioner/README.md`
  - Image artifacts location (`provisioner/outputs/<env>/<role>.img`)
  - Metadata JSON format
  - Remote upload placeholders
- [ ] Document 5-phase safety pattern (validate, backup, apply, test, result)
- [ ] Document dependency chain between roles

### 1.3 Document Container-Orchestration Module
- [ ] Add Requirements section to `container-orchestration/README.md`
  - API metadata.json consumption
  - Kubespray inventory structure (INI + group_vars)
  - Docker requirements and version
  - SSH key requirements
- [ ] Add Outputs section to `container-orchestration/README.md`
  - Kubernetes cluster state
  - Kubeconfig location
  - Cluster endpoints
- [ ] **CRITICAL**: Document Docker mounting requirements
  - Host inventory path → Container `/kubespray/inventory/runtime/`
  - Host SSH key → Container `/root/.ssh/id_rsa`
  - Permissions requirements (600 for SSH key)
- [ ] Document provider interface (deploy.sh, reset.sh, validate.sh)
- [ ] Document validation checks (inventory files, connectivity, network plugin)

### 1.4 Document Platform Module
- [ ] Add Requirements section to `platform/README.md`
  - Running Kubernetes cluster requirement
  - Kubeconfig access
  - API outputs (platform.yaml)
  - Environment variables for secrets
- [ ] Add Outputs section to `platform/README.md`
  - ArgoCD applications
  - Generated sealed secrets
  - Platform service endpoints
- [ ] **CRITICAL**: Document secrets handling mechanism
  - Secret spec format
  - Environment variable sourcing
  - Sealed-secrets rendering process
  - PushSecret for Vault sync
- [ ] Document bootstrap sequence
- [ ] Document sync wave ordering
- [ ] Document app-of-apps pattern

### 1.5 Document Business Module
- [ ] Add Requirements section to `business/README.md`
  - API outputs (business.yaml)
  - Platform module dependencies
  - ArgoCD availability
- [ ] Add Outputs section to `business/README.md`
  - ArgoCD applications
  - Deployed resources per app
- [ ] Document app-of-apps umbrella chart
- [ ] Document integration with platform namespaces/secrets

### 1.6 Document Config Module
- [ ] Create `config/packages/infrastructure/README.md`
  - Document YAML structure requirements
  - List required files (hosts.yaml, networks.yaml, proxmox.yaml)
- [ ] Create `config/packages/provisioner/README.md`
  - Document role definitions format
  - List required files (roles.yaml)
- [ ] Create `config/packages/kubespray/README.md`
  - Document cluster settings format
  - Document inventory structure (YAML format, not INI yet)
- [ ] Create `config/packages/platform/README.md`
  - Document stack definitions format
  - List required files (stacks.yaml)
- [ ] Create `config/packages/business/README.md`
  - Document application definitions format
  - List required files (apps.yaml)

### 1.7 Create Migration Guide
- [ ] Create `docs/migration/api-config-separation.md`
  - Explain config package restructuring
  - Explain YAML-only input requirement
  - Explain environment override mechanism
  - Provide before/after examples
  - Document breaking changes
  - Provide migration checklist for users

---

## Phase 2: Environment Schemas

### 2.1 Create Schema Directory
- [ ] Create `api/schemas/environments/` directory

### 2.2 Infrastructure Environment Schema
- [ ] Create `api/schemas/environments/infrastructure.schema.yaml`
  - configPackage (required, string)
  - environment (required, enum: development/staging/production)
  - proxmox object (api_token, endpoint, node_name, datastore)
  - ssh object (private_key_path, public_key)
  - hosts_override array (name, ip, role, cpu, memory)
- [ ] Add JSON Schema validation tests

### 2.3 Provisioner Environment Schema
- [ ] Create `api/schemas/environments/provisioner.schema.yaml`
  - configPackage (required)
  - environment (required)
  - ansible_vault_password (string)
  - ssh_keys object (paths, passphrases)
  - role_overrides object (per-role config overrides)
- [ ] Add validation tests

### 2.4 Kubespray Environment Schema
- [ ] Create `api/schemas/environments/kubespray.schema.yaml`
  - configPackage (required)
  - environment (required)
  - docker object (image version, registry)
  - ssh object (key_path, user, port)
  - inventory_overrides object (hosts, groups)
  - cluster_overrides object (network_plugin, service_addresses, etc.)
- [ ] Add validation tests

### 2.5 Platform Environment Schema
- [ ] Create `api/schemas/environments/platform.schema.yaml`
  - configPackage (required)
  - environment (required)
  - argocd object (admin_password, url)
  - sealed_secrets object (public_key_path)
  - stacks object (base, monitoring, ml enabled flags)
  - secrets object (key-value pairs for secret specs)
- [ ] Add validation tests

### 2.6 Business Environment Schema
- [ ] Create `api/schemas/environments/business.schema.yaml`
  - configPackage (required)
  - environment (required)
  - apps array (name, namespace, values overrides)
  - namespaces object (environment-specific namespace configs)
- [ ] Add validation tests

---

## Phase 3: Config Package Restructuring (Master Config Pattern)

### 3.1 Create Config Package Structure
- [ ] Create `config/packages/core/` directory
- [ ] Create `config/packages/core/platforms/` subdirectory
- [ ] Create `config/packages/core/orchestrators/` subdirectory
- [ ] Create `config/packages/core/platform/` subdirectory
- [ ] Create `config/packages/core/business/` subdirectory

### 3.2 Create Master Configuration
- [ ] Create `config/packages/core/config.yaml` with:
  - infrastructure.platform (proxmox, aws, gcp, azure, baremetal)
  - infrastructure.provider (terraform, pulumi, ansible)
  - container_orchestration.orchestrator (kubespray, kubekey, kind)
  - container_orchestration.provider (docker, podman, native)
  - platform.enabled (boolean)
  - business.enabled (boolean)
- [ ] Document master config schema and available choices
- [ ] Set initial values to current deployment (proxmox + kubespray)

### 3.3 Move Platform-Agnostic Configs
- [ ] Convert/move host definitions to `config/packages/core/hosts.yaml` (YAML format, platform-agnostic)
- [ ] Convert/move network definitions to `config/packages/core/networks.yaml` (YAML format, platform-agnostic)
- [ ] Ensure these configs work across all platform choices
- [ ] Remove sensitive data (mark for env override)

### 3.4 Create Platform-Specific Configs
- [ ] Create `config/packages/core/platforms/proxmox.yaml` (endpoint, node_name, datastore - non-sensitive only)
- [ ] Create `config/packages/core/platforms/aws.yaml` (region, vpc_id, instance_type) - stub for future
- [ ] Create `config/packages/core/platforms/gcp.yaml` - stub for future
- [ ] Create `config/packages/core/platforms/azure.yaml` - stub for future
- [ ] Create `config/packages/core/platforms/baremetal-libvirt.yaml` - stub for future
- [ ] Document which fields come from platform config vs environment override

### 3.5 Create Orchestrator-Specific Configs
- [ ] Create `config/packages/core/orchestrators/kubespray.yaml` (cluster settings, network plugin, etc.)
- [ ] Create `config/packages/core/orchestrators/kubekey.yaml` - stub for future
- [ ] Create `config/packages/core/orchestrators/kind.yaml` - stub for future
- [ ] Convert existing Kubespray inventory structure to YAML format for template rendering

### 3.6 Move Platform and Business Configs
- [ ] Convert/move stack definitions to `config/packages/core/platform/stacks.yaml`
- [ ] Convert/move app definitions to `config/packages/core/business/apps.yaml`

### 3.7 Create Package Manifest
- [ ] Create `config/packages/core/package.json` with:
  - id: "core"
  - version: "v1.0.0"
  - description: "Master configuration with platform/orchestrator choices"
  - files array listing all config files (including wildcards like "platforms/*.yaml")
- [ ] Document versioning strategy for master config

### 3.8 Create Config Package README
- [ ] Create `config/packages/core/README.md` documenting:
  - Master config pattern
  - How to add new platforms/orchestrators
  - Platform-agnostic vs platform-specific config separation
  - Environment override patterns
  - Examples for switching platforms

### 3.9 Validation
- [ ] Update `config/validate.sh` to:
  - Validate master config structure
  - Check that selected platform/orchestrator configs exist
  - Ensure platform-agnostic configs don't contain platform-specific fields
  - Verify no sensitive data in any config files
- [ ] Add tests for package manifest
- [ ] Test config loading with different platform/orchestrator selections

---

## Phase 4: Go Template Creation (Platform/Orchestrator Organized)

### 4.1 Create Template Directory Structure
- [ ] Create `api/templates/infrastructure/` with platform subdirectories
- [ ] Create `api/templates/infrastructure/proxmox/terraform/`
- [ ] Create `api/templates/infrastructure/aws/terraform/` (stub for future)
- [ ] Create `api/templates/infrastructure/gcp/terraform/` (stub for future)
- [ ] Create `api/templates/infrastructure/azure/terraform/` (stub for future)
- [ ] Create `api/templates/infrastructure/baremetal/libvirt/` (stub for future)
- [ ] Create `api/templates/provisioner/`
- [ ] Create `api/templates/container-orchestration/kubespray/`
- [ ] Create `api/templates/container-orchestration/kubekey/` (stub for future)
- [ ] Create `api/templates/container-orchestration/kind/` (stub for future)
- [ ] Create `api/templates/platform/`
- [ ] Create `api/templates/business/`

### 4.2 Infrastructure Templates (Proxmox)
- [ ] Create `api/templates/infrastructure/proxmox/terraform/terraform.tfvars.tmpl`
  - Global config section (environment, prefix, proxmox-specific config)
  - Networking section (VLANs, gateway, DNS)
  - Hosts section (iterate over hosts, generate host blocks)
  - Test with sample merged data (platform-agnostic + proxmox-specific + env overrides)
  - Validate output matches current terraform.tfvars format

### 4.2b Infrastructure Templates (AWS - Stub)
- [ ] Create `api/templates/infrastructure/aws/terraform/terraform.tfvars.tmpl` (stub with TODOs)
  - Document AWS-specific variables needed
  - Add placeholder template structure
  - Note: To be implemented when AWS support added

### 4.3 Provisioner Templates
- [ ] Create `api/templates/provisioner/config.json.tmpl`
  - Role definitions
  - Static vs dynamic config
  - Ansible variables
  - Test with sample data
  - Validate JSON output

### 4.4 Container-Orchestration Templates (Kubespray)
- [ ] Create `api/templates/container-orchestration/kubespray/inventory.ini.tmpl`
  - [all] section with host list
  - [kube_control_plane] section (filter by role)
  - [etcd] section (filter by role)
  - [kube_node] section (filter by role)
  - Test with sample data
  - Validate INI output format
  - Ensure Docker mount compatibility (will be mounted to /kubespray/inventory/runtime/)
- [ ] Create `api/templates/container-orchestration/kubespray/group_vars.yaml.tmpl`
  - Cluster settings from orchestrator config
  - Network plugin config
  - Service/pod CIDR
  - Test with sample data

### 4.4b Container-Orchestration Templates (Kubekey/Kind - Stubs)
- [ ] Create `api/templates/container-orchestration/kubekey/config.yaml.tmpl` (stub with TODOs)
- [ ] Create `api/templates/container-orchestration/kind/config.yaml.tmpl` (stub with TODOs)

### 4.5 Platform Templates
- [ ] Create `api/templates/platform/values.yaml.tmpl`
  - Cluster name
  - Stack configurations (base, monitoring, ml)
  - Git repo settings
  - Test with sample data
  - Validate Helm values format

### 4.6 Business Templates
- [ ] Create `api/templates/business/values.yaml.tmpl`
  - Applications list
  - Namespace settings
  - App-specific overrides
  - Test with sample data

### 4.7 Template Testing
- [ ] Create `api/internal/generators/testdata/` with sample YAML inputs for each platform/orchestrator
  - Sample data for Proxmox + Kubespray
  - Sample data for AWS + Kubespray (for future testing)
- [ ] Add unit tests for each template
- [ ] Test Proxmox template with actual config structure
- [ ] Verify generated outputs match expected formats
- [ ] Test template error handling (missing fields, invalid data)
- [ ] Test template selection logic (correct template chosen based on master config)

---

## Phase 5: API CLI Refactoring

### 5.1 Master Config Reader Implementation
- [ ] Create `api/internal/config/` package
- [ ] Implement master config loader to read `config/packages/core/config.yaml`
- [ ] Parse platform/provider/orchestrator selections
- [ ] Add validation for master config structure
- [ ] Add unit tests for master config reader

### 5.2 Template Path Resolver
- [ ] Create `api/internal/templates/resolver.go`
- [ ] Implement template path resolution based on platform/provider/orchestrator selections
- [ ] Map platform="proxmox" + provider="terraform" → `api/templates/infrastructure/proxmox/terraform/`
- [ ] Map orchestrator="kubespray" → `api/templates/container-orchestration/kubespray/`
- [ ] Handle missing template gracefully (error message guiding user)
- [ ] Add unit tests for path resolver

### 5.3 Config Merger Implementation
- [ ] Create `api/internal/merger/` package
- [ ] Implement platform-agnostic config loading (hosts.yaml, networks.yaml)
- [ ] Implement platform-specific config loading based on master config selection
- [ ] Implement orchestrator-specific config loading
- [ ] Implement environment override loading from `<module>/environments/<env>.yaml`
- [ ] Implement merge logic (deep merge, override precedence: base < platform-specific < env override)
- [ ] Add unit tests for merger with different platform combinations

### 5.4 Environment Validation
- [ ] Update `api/internal/validators/` to handle environment schemas
- [ ] Add `--target environments` flag to `api validate` command
- [ ] Implement environment file validation against `api/schemas/environments/<module>.schema.yaml`
- [ ] Add validation tests

### 5.5 Template Rendering
- [ ] Create `api/internal/generators/renderer.go`
- [ ] Implement Go `text/template` loading and execution
- [ ] Add template helper functions (if needed)
- [ ] Implement output file writing
- [ ] Add error handling for template syntax errors
- [ ] Add unit tests for renderer

### 5.6 Update Generate Command
- [ ] Refactor `api/internal/commands/generate.go` with new pipeline:
  1. Load master config from `config/packages/core/config.yaml`
  2. Extract platform/provider/orchestrator selections
  3. Load platform-agnostic configs (hosts.yaml, networks.yaml)
  4. Load platform-specific config based on selection (platforms/proxmox.yaml)
  5. Load orchestrator-specific config based on selection (orchestrators/kubespray.yaml)
  6. Load environment overrides from modules
  7. Validate environment files against schemas
  8. Merge: base + platform-specific + orchestrator-specific + env overrides
  9. Validate merged configs against general schemas
  10. Resolve template paths based on platform/orchestrator selections
  11. Render selected templates with merged data
  12. Write outputs to `api/outputs/<env>/` with consistent structure
  13. Generate metadata.json with master config info
- [ ] Update command flags (keep existing, add new if needed)
- [ ] Add integration tests covering Proxmox + Kubespray combination

### 5.7 Metadata Generation
- [ ] Update metadata.json generation to include:
  - All module output paths
  - Master config selections (platform, provider, orchestrator)
  - Config package version
  - Template paths used
  - Generation timestamp
- [ ] Ensure absolute paths for all file references
- [ ] Add validation that metadata references existing files

---

## Phase 6: Module Environment Files

### 6.1 Create Environment Directories
- [ ] Create `infrastructure/environments/` (if not exists)
- [ ] Create `provisioner/environments/` (if not exists)
- [ ] Create `container-orchestration/environments/` (if not exists)
- [ ] Create `platform/environments/` (if not exists)
- [ ] Create `business/environments/` (if not exists)

### 6.2 Extract Secrets from Config Packages
- [ ] Identify sensitive data in `config/packages/infrastructure/`
- [ ] Move to `infrastructure/environments/development.yaml`
- [ ] Identify sensitive data in `config/packages/provisioner/`
- [ ] Move to `provisioner/environments/development.yaml`
- [ ] Identify sensitive data in `config/packages/kubespray/`
- [ ] Move to `container-orchestration/environments/development.yaml`
- [ ] Identify sensitive data in `config/packages/platform/`
- [ ] Move to `platform/environments/development.yaml`
- [ ] Identify sensitive data in `config/packages/business/`
- [ ] Move to `business/environments/development.yaml`

### 6.3 Setup Git Protection
- [ ] Add `*/environments/*.yaml` to `.gitignore` (or create encryption guide)
- [ ] Document sealed-secrets usage for production
- [ ] Document SOPS usage as alternative
- [ ] Create `.env.example` templates for each module

### 6.4 Validate Environment Files
- [ ] Test environment validation for each module
- [ ] Ensure schema validation catches common errors
- [ ] Test merge behavior with base configs

---

## Phase 7: Integration Testing

### 7.1 Setup Test Environment
- [ ] Prepare clean test cluster/infrastructure
- [ ] Backup existing configurations
- [ ] Ensure all tools available (terraform, docker, kubectl, jq, etc.)

### 7.2 End-to-End Deployment Test
- [ ] Run `./api/bin/api validate --target definitions`
- [ ] Run `./api/bin/api validate --target environments`
- [ ] Run `./api/bin/api generate env --id development --config infrastructure`
- [ ] Verify all output files generated correctly
  - Check terraform.tfvars format
  - Check provisioner.json format
  - Check kubespray inventory.ini format
  - Check platform.yaml format
  - Check business.yaml format
- [ ] Verify metadata.json contains all expected paths

### 7.3 Module Integration Testing
- [ ] Test infrastructure deployment
  - Run `infrastructure/deploy.sh --env development --phase bootstrap`
  - Verify API artifacts generated automatically
  - Run `infrastructure/deploy.sh --env development --phase templates`
  - Verify tfvars staged correctly
  - Check Terraform runs successfully with generated vars
- [ ] Test provisioner builds
  - Run `./api/bin/api provision build --role k8s-master --env development`
  - Verify provisioner.json consumed correctly
  - Check metadata generated
- [ ] Test container-orchestration deployment
  - Run `container-orchestration/providers/kubespray/validate.sh --env development`
  - Verify inventory validation passes
  - Run `container-orchestration/providers/kubespray/deploy.sh --env development`
  - **CRITICAL**: Verify Docker mounts work correctly
  - Check inventory.ini read from correct location
  - Check SSH key mounted properly
  - Verify Kubernetes cluster deploys
- [ ] Test platform deployment
  - Run `platform/run.sh validate --env development`
  - Verify platform.yaml consumed correctly
  - Run `platform/run.sh deploy --env development`
  - **CRITICAL**: Verify secrets rendering works
  - Check sealed-secrets generated from env vars
  - Verify ArgoCD applications created
- [ ] Test business deployment
  - Deploy business app-of-apps with generated business.yaml
  - Verify applications sync correctly

### 7.4 Document Validation Results
- [ ] Create/update `docs/validation.md`
- [ ] Document test environment details
- [ ] Include command outputs
- [ ] Note any issues encountered and resolutions
- [ ] Confirm all modules work with new architecture

---

## Phase 8: Cleanup and Release

### 8.1 Remove Legacy Code
- [ ] Remove `api/definitions/` directory (after confirming migration)
- [ ] Remove old config files from `config/packages/core/`
- [ ] Update any remaining references to old paths
- [ ] Archive old documentation

### 8.2 Update CI/CD
- [ ] Update CI pipelines to use new API commands
- [ ] Update validation steps in CI
- [ ] Test CI pipeline end-to-end

### 8.3 Update Root Documentation
- [ ] Update top-level `README.md` with new architecture
- [ ] Update `docs/general/modular-architecture.md` with API/Config separation
- [ ] Update quickstart guides
- [ ] Update troubleshooting docs

### 8.4 Release
- [ ] Tag Git release with new version
- [ ] Write release notes highlighting changes
- [ ] Document upgrade path for existing deployments
- [ ] Notify team of changes

---

## Verification Checklist

After implementation, verify:
- [ ] All schemas validate correctly
- [ ] All templates render valid outputs
- [ ] API CLI generates all required files
- [ ] No sensitive data in git-tracked config packages
- [ ] Environment overrides work as expected
- [ ] Kubespray Docker mounting works correctly
- [ ] Platform secrets rendering works correctly
- [ ] End-to-end deployment succeeds
- [ ] Module READMEs accurately document contracts
- [ ] Migration guide is complete and tested
- [ ] OpenSpec validation passes
