## Why

RFC-PLATARCH-0001 incorrectly conflates "Platform Applications" with tenant business workloads and lacks clear criteria for base chart usage. The platform needs a binary categorization that determines which components use the base chart and which cannot (to avoid circular dependencies).

## What Changes

### Binary Component Categorization

- **BREAKING**: Replace multi-category taxonomy with binary categorization:
  - **Infrastructure Provider**: Components that PROVIDE capabilities consumed by base chart templates (DO NOT use base chart)
  - **Platform Consumer**: Components that CONSUME capabilities provided by Infrastructure Providers (MUST use base chart)

- **Decision Criteria**: Does this component PROVIDE a capability that base chart templates consume?
  - YES → Infrastructure Provider (no base chart)
  - NO → Platform Consumer (must use base chart)

### DAG-Based Capability Resolution

- **MODIFIED**: Clarify capability orchestration uses DAG (Directed Acyclic Graph) resolution
- **Directed**: Dependencies flow from provider to consumer
- **Acyclic**: Circular dependencies rejected at declaration time
- Components deploy when ALL required capabilities are satisfied
- No phases, no layers—purely DAG traversal
- The RFC describes WHAT the model is, not HOW to implement orchestration

### Base Chart Scope

- **MODIFIED**: Base chart is a Helm library chart for Platform Consumers ONLY
- **ADDED**: Clear boundary—Infrastructure Providers CANNOT use base chart (circular dependency)
- **ADDED**: Base chart templates consume capabilities from Infrastructure Providers:
  - ExternalSecret (Vault, ESO)
  - Keycloak client (Keycloak)
  - PostgreSQL claim (Zalando Operator)
  - Kafka topic (Strimzi)
  - Certificate (cert-manager)
  - Crossplane claims (Crossplane)

### Terminology Corrections

- **MODIFIED**: "Platform Application" → "Platform Consumer" or "Infrastructure Provider"
- **ADDED**: "Tenant Application" as subset of Platform Consumer
- **REMOVED**: Layer/phase terminology

### Cross-RFC Alignment

- **MODIFIED**: Ensure RFC-PLATARCH-0001 remains an informative design RFC
- Implementation details deferred to domain-specific RFCs

## Impact

- **Affected specs**: platform-architecture (binary categorization, label schema)
- **Affected code**: `docs/platform/rfcs/platform-arch/` (all 13 files)
- **Affected RFCs**: Cross-references in related RFCs
- **Migration**: Terminology updates; capability model preserved
