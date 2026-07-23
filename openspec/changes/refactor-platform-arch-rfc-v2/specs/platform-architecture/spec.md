## ADDED Requirements

### Requirement: Binary Component Categorization

The platform SHALL classify components into exactly two categories that determine base chart usage.

#### Scenario: Infrastructure Provider classification
- **WHEN** a component PROVIDES a capability that base chart templates consume
- **THEN** the component SHALL be classified as Infrastructure Provider
- **AND** the component SHALL NOT use the base chart
- **AND** examples include cert-manager, Crossplane, Vault, ESO, Keycloak, Zalando Operator, Strimzi, Rook-Ceph, MetalLB, ingress-nginx, ArgoCD

#### Scenario: Platform Consumer classification
- **WHEN** a component CONSUMES capabilities provided by Infrastructure Providers
- **AND** the component does NOT provide capabilities consumed by base chart templates
- **THEN** the component SHALL be classified as Platform Consumer
- **AND** the component MUST use the base chart
- **AND** examples include Backstage, Harbor, Grafana, Loki, Tempo, tenant applications

#### Scenario: Binary decision test
- **WHEN** determining a component's category
- **THEN** the decision SHALL be: "Does base chart depend on this component's capability?"
- **AND** if YES → Infrastructure Provider (no base chart)
- **AND** if NO → Platform Consumer (must use base chart)

### Requirement: DAG-Based Dependency Resolution

The capability orchestration model SHALL use Directed Acyclic Graph (DAG) based dependency resolution.

#### Scenario: Immediate deployment for components with no requirements
- **WHEN** a component declares no required capabilities
- **THEN** the component MAY deploy immediately
- **AND** deployment does not wait for any other component

#### Scenario: Concurrent deployment for independent components
- **WHEN** multiple components have their required capabilities satisfied
- **AND** there are no dependencies between these components
- **THEN** the components MAY deploy concurrently
- **AND** no global ordering constrains their deployment

#### Scenario: Dependency satisfaction before deployment
- **WHEN** a component declares required capabilities
- **THEN** the component SHALL NOT deploy until ALL required capabilities are satisfied
- **AND** satisfaction is determined by capability provider readiness

#### Scenario: Circular dependency rejection
- **WHEN** capability declarations form a cycle
- **THEN** the orchestrator SHALL reject the configuration at declaration time
- **AND** deployment SHALL NOT proceed until the cycle is resolved

### Requirement: Base Chart Scope Boundary

The base chart SHALL be used exclusively by Platform Consumers and SHALL NOT be used by Infrastructure Providers.

#### Scenario: Infrastructure Provider deployment
- **WHEN** an Infrastructure Provider is deployed
- **THEN** the component SHALL use its upstream chart directly
- **AND** the component SHALL NOT include platform-base as a dependency
- **AND** circular dependency is avoided

#### Scenario: Platform Consumer deployment
- **WHEN** a Platform Consumer is deployed
- **THEN** the component MUST include platform-base as a Helm dependency
- **AND** the component SHALL use base chart templates for platform integration

#### Scenario: Base chart template scope
- **WHEN** the base chart provides templates
- **THEN** templates SHALL consume capabilities from Infrastructure Providers
- **AND** templates SHALL include ExternalSecret, Keycloak client, PostgreSQL claim, Kafka topic, Certificate, Crossplane claims
- **AND** templates SHALL NOT be added until the corresponding Infrastructure Provider is deployed

### Requirement: RFC Scope Boundaries

RFC-PLATARCH-0001 SHALL define architecture model and design, deferring implementation details to domain-specific RFCs.

#### Scenario: Orchestration implementation deference
- **WHEN** the RFC describes capability orchestration
- **THEN** the RFC SHALL describe the model (capabilities, providers, consumers, contracts, DAG)
- **AND** the RFC SHALL defer implementation mechanisms to RFC-DEPLOY-0001
- **AND** the RFC SHALL NOT prescribe specific orchestration technologies

#### Scenario: Secret management deference
- **WHEN** the RFC describes secret requirements
- **THEN** the RFC SHALL reference RFC-SECOPS-0001 for secret lifecycle
- **AND** the RFC SHALL NOT duplicate secret management specifications

## MODIFIED Requirements

### Requirement: Component Categorization Model

Components SHALL be classified using binary categories that determine base chart usage.

#### Scenario: Category determines base chart usage
- **WHEN** a component is assigned a category
- **THEN** the category SHALL determine whether the component uses base chart
- **AND** Infrastructure Provider → no base chart
- **AND** Platform Consumer → must use base chart

#### Scenario: No intermediate categories
- **WHEN** classifying a component
- **THEN** there SHALL be exactly two categories
- **AND** every component falls into exactly one category
- **AND** the decision is binary based on capability provision

### Requirement: Capability Orchestration Model

The orchestrator SHALL deploy components based on DAG capability resolution.

#### Scenario: DAG-based deployment
- **WHEN** the orchestrator evaluates deployment readiness
- **THEN** the orchestrator SHALL check if ALL required capabilities are satisfied
- **AND** deployment proceeds when all requirements are met
- **AND** no phase or layer hierarchy constrains deployment order

#### Scenario: Deterministic resolution
- **WHEN** the same capability dependency DAG is resolved multiple times
- **THEN** the final state SHALL be identical
- **AND** the deployment order may vary but the end state is deterministic

### Requirement: Platform Consumer Definition

Platform Consumers SHALL be components that consume platform capabilities and MUST use the base chart.

#### Scenario: Platform Consumer characteristics
- **WHEN** evaluating whether a component is a Platform Consumer
- **THEN** the component SHALL consume capabilities from Infrastructure Providers
- **AND** the component SHALL NOT provide capabilities consumed by base chart templates
- **AND** examples include Backstage, Harbor, Grafana, tenant applications

#### Scenario: Tenant Application as Platform Consumer
- **WHEN** a tenant deploys a business workload
- **THEN** the workload SHALL be classified as a Platform Consumer
- **AND** the workload MUST use the base chart
- **AND** the workload consumes platform capabilities

## REMOVED Requirements

### Requirement: Multi-Category Taxonomy

**Reason**: The seven-category taxonomy created ambiguity about base chart usage. Binary categorization provides clear decision criteria: Infrastructure Provider (no base chart) vs Platform Consumer (must use base chart).

**Migration**: Replace with binary categorization. Sub-classifications (operator, service, tenant-app) become optional labels, not primary categories.

### Requirement: Layered Architecture Model

**Reason**: The layered model implied hierarchical deployment ordering. Binary categorization focuses on base chart usage, not deployment sequence. Deployment order is determined solely by DAG capability resolution.

**Migration**: Remove layer terminology. Categories are for base chart decision, not deployment ordering.

### Requirement: Phase-Based Deployment

**Reason**: Phase-based deployment creates artificial sequential constraints. DAG-based capability resolution provides flexibility and parallelism.

**Migration**: Remove all phase terminology. Document that deployment order is determined by capability DAG resolution.

### Requirement: Platform Application Terminology

**Reason**: "Platform Application" was ambiguous. Split into Infrastructure Provider and Platform Consumer based on capability provision.

**Migration**: Use "Infrastructure Provider" for capability providers, "Platform Consumer" for capability consumers.
