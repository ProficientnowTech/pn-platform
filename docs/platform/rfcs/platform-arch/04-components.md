```
RFC-PLATARCH-0001                                              Section 4
Category: Standards Track                            Component Taxonomy
```

# 4. Component Taxonomy

[← Architecture](./03-architecture.md) | [Index](./00-index.md#table-of-contents) | [Next: Orchestration →](./05-capability-orchestration.md)

---

## 4.1 Overview

This section defines the classification of components within the platform. Components are categorized based on their role, ownership, and relationship to the platform. This taxonomy governs how components are managed, what guarantees they receive, and what constraints apply to them.

---

## 2. Component Classification

### 2.1 Classification Dimensions

Components are classified along three dimensions:

**Ownership:** Who is responsible for the component (platform team or application team)

**Scope:** What the component serves (platform-wide or application-specific)

**Lifecycle:** How the component's lifecycle relates to other components

### 2.2 Primary Categories

The platform recognizes four primary component categories:

| Category | Ownership | Scope | Example |
|----------|-----------|-------|---------|
| Platform Core | Platform | Platform-wide | Orchestrator, operators |
| Shared Infrastructure | Platform | Platform-wide | Databases, queues |
| Platform Applications | Application | Application-specific | Business workloads |
| Platform Utilities | Platform | Platform-wide | Monitoring, logging |

---

## 3. Platform Core Components

### 3.1 Definition

Platform core components are the foundational services that enable the platform to function. Without these components, the platform cannot operate. They are owned and operated by the platform team.

### 3.2 Examples

**Orchestrator:** The capability orchestration engine that sequences deployments.

**ArgoCD:** The GitOps deployment engine that applies configurations to the cluster.

**Operators:** Controllers that manage specific resource types (cert-manager, external-secrets-operator, etc.).

**CRDs:** Custom Resource Definitions that extend Kubernetes for platform capabilities.

### 3.3 Characteristics

- Deployed at platform initialization
- Have cluster-wide scope
- Require elevated permissions
- Are prerequisites for other components
- Have independent lifecycle from applications

### 3.4 Management Rules

Platform core components:
- MUST be managed through GitOps
- MUST be deployed before shared infrastructure
- MUST be owned exclusively by platform team
- MUST NOT be modified by application teams
- MUST have documented upgrade procedures

---

## 4. Shared Infrastructure Components

### 4.1 Definition

Shared infrastructure components are services that provide capabilities to multiple applications. They are platform-owned but application-facing. They exist because running them per-application would be wasteful or operationally untenable.

### 4.2 Eligibility Criteria

Infrastructure is eligible for shared status when it meets ALL of the following criteria:

**Multi-tenant capability:** The infrastructure can serve multiple applications with appropriate isolation.

**Operational complexity:** The infrastructure requires specialized knowledge to operate correctly.

**Resource efficiency:** Sharing provides meaningful resource savings over per-application deployment.

**Platform commitment:** The platform team can commit to the guarantees required by consumers.

### 4.3 Categories of Shared Infrastructure

**Data Services:**
- Relational databases (PostgreSQL, MySQL)
- Document databases (MongoDB)
- Key-value stores (Redis)
- Message queues (RabbitMQ, Kafka)

**Security Services:**
- Identity providers (Keycloak)
- Secret management (Vault, External Secrets)
- Certificate management (cert-manager)

**Integration Services:**
- API gateways
- Service mesh (Istio, Linkerd)
- Event buses

### 4.4 Characteristics

- Serve multiple application consumers
- Provide capability contracts
- Are platform-owned
- Have lifecycle independent of any single application
- Require availability and durability guarantees

### 4.5 Management Rules

Shared infrastructure components:
- MUST be owned by platform team
- MUST publish capability contracts
- MUST meet availability guarantees
- MUST provide backup and recovery
- MUST support upgrade without consumer downtime
- MUST NOT be provisioned per-application

---

## 5. Platform Applications

### 5.1 Definition

A platform application is a workload that runs on the platform and integrates through the canonical base chart. Platform applications are business workloads that consume platform capabilities.

### 5.2 What Makes an Application a Platform Application

An application is a platform application when it:

**Uses the base chart:** Integration is through the single canonical base chart. There are no alternative integration mechanisms.

**Declares capabilities:** The application explicitly declares what capabilities it requires and what capabilities it provides.

**Follows governance:** The application complies with platform governance rules including namespace isolation, naming conventions, and security policies.

**Accepts platform identity:** The application uses platform-assigned identity for authentication and authorization.

### 5.3 What Is NOT a Platform Application

The following are NOT platform applications:

**Applications with custom integration:** Applications that bypass the base chart are not platform applications.

**Applications without capability declarations:** Applications that do not declare capabilities cannot be orchestrated.

**Applications violating governance:** Applications that violate platform rules cannot be deployed.

**External workloads:** Workloads running outside the platform cluster are not platform applications.

### 5.4 Characteristics

- Owned by application teams
- Integrate through base chart
- Consume capabilities from shared infrastructure
- May provide capabilities to other applications
- Have lifecycle managed through GitOps

### 5.5 Management Rules

Platform applications:
- MUST use the canonical base chart
- MUST declare all capability requirements
- MUST declare all capability provisions
- MUST use platform secret management
- MUST use platform identity
- MUST comply with security policies
- MUST NOT create CRDs
- MUST NOT install operators

---

## 6. Platform Utilities

### 6.1 Definition

Platform utilities are components that support platform operation but are not core to orchestration or infrastructure provision. They provide observability, debugging, and operational support.

### 6.2 Examples

**Monitoring:** Prometheus, Grafana for metrics collection and visualization.

**Logging:** Elasticsearch, Loki for log aggregation.

**Tracing:** Jaeger, Zipkin for distributed tracing.

**Alerting:** Alertmanager for alert routing.

### 6.3 Characteristics

- Support platform operations
- Are platform-owned
- May be consumed by applications for observability
- Do not block application deployment
- Have defined interfaces for integration

### 6.4 Management Rules

Platform utilities:
- MUST be managed by platform team
- MUST provide standard interfaces for integration
- SHOULD NOT be required for application startup
- MUST follow platform security policies

---

## 7. The Canonical Base Chart

### 7.1 Why a Single Base Chart

The base chart is the single integration mechanism for platform applications. All platform applications use this chart. There are no alternatives.

The single base chart exists because:

**Uniformity:** Every application integrates the same way. Behavior is predictable.

**Completeness:** The base chart embeds all required integration. Applications cannot skip integration points.

**Evolvability:** Platform changes are delivered through the base chart. All applications receive changes.

**Governance:** The base chart enforces governance. Applications cannot bypass governance.

### 7.2 Base Chart Responsibilities

The base chart is responsible for:

**Capability declaration validation:** Ensuring applications declare their requirements.

**Secret integration:** Wiring applications to platform secret management.

**Identity integration:** Wiring applications to platform identity.

**Network policy generation:** Creating appropriate network policies.

**Resource configuration:** Setting resource limits and requests.

**Monitoring integration:** Wiring applications to platform observability.

### 7.3 Base Chart Versioning

The base chart is versioned using semantic versioning:

**Major version:** Breaking changes requiring application modification.

**Minor version:** New features with backward compatibility.

**Patch version:** Bug fixes with full backward compatibility.

Applications specify the base chart version they use. Upgrades are coordinated platform events.

### 7.4 Base Chart Evolution

Base chart changes follow the change management process:

1. RFC for significant changes
2. Beta release for testing
3. Deprecation notice for breaking changes
4. Migration period for affected applications
5. General availability release

---

## 8. Mandatory Guarantees for Shared Infrastructure

### 8.1 Availability Guarantee

Shared infrastructure MUST provide defined availability targets. Availability is measured as the percentage of time the capability is accessible and functional.

Availability guarantees are documented in capability contracts. Consumers can depend on these guarantees for their own availability planning.

### 8.2 Durability Guarantee

Shared infrastructure that stores data MUST provide durability guarantees. Durability is measured as the probability of data being preserved over time.

Durability guarantees specify:
- What data is protected
- What failure scenarios are covered
- What recovery procedures exist

### 8.3 Backup Guarantee

Shared infrastructure MUST provide backup capability. Backups enable recovery from failures beyond what durability guarantees cover.

Backup guarantees specify:
- Backup frequency
- Retention period
- Recovery procedures
- Recovery time objectives

### 8.4 Upgrade Guarantee

Shared infrastructure MUST support upgrades without consumer downtime. Consumers must not need to coordinate with infrastructure upgrades.

Upgrade guarantees specify:
- Upgrade procedures
- Compatibility rules
- Notification requirements

### 8.5 Stability Guarantee

Shared infrastructure MUST provide stable interfaces. Interface changes follow versioning and deprecation rules.

Stability guarantees specify:
- Versioning scheme
- Deprecation timeline
- Migration support

---

## 9. Component Relationships

### 9.1 Dependency Graph

Components form a directed acyclic graph of dependencies:

```
Platform Core
    ↓
Shared Infrastructure
    ↓
Platform Applications
```

Platform utilities connect at multiple levels but do not block the primary dependency chain.

### 9.2 Capability Flow

Capabilities flow from providers to consumers:

1. Platform core provides orchestration capabilities
2. Shared infrastructure provides data/security/integration capabilities
3. Platform applications consume capabilities
4. Platform applications may provide capabilities to other applications

### 9.3 Ownership Boundaries

Ownership creates hard boundaries:

- Platform team owns: Platform core, shared infrastructure, platform utilities
- Application teams own: Their platform applications

Ownership boundaries determine who can modify what. Cross-boundary modification is prohibited.

---

## 10. Summary

### 10.1 Component Categories

| Category | Owner | Scope | Integration |
|----------|-------|-------|-------------|
| Platform Core | Platform | Cluster | Direct |
| Shared Infrastructure | Platform | Cluster | Capability contracts |
| Platform Applications | Application | Namespace | Base chart |
| Platform Utilities | Platform | Cluster | Standard interfaces |

### 10.2 Key Rules

| Rule | Applies To |
|------|------------|
| Must use base chart | Platform Applications |
| Must provide guarantees | Shared Infrastructure |
| Must be platform-owned | Shared Infrastructure, Platform Core |
| Must declare capabilities | Platform Applications, Shared Infrastructure |

### 10.3 Base Chart Mandate

- Single integration mechanism
- No alternatives permitted
- Enforces governance
- Enables platform evolution

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 3. Architecture](./03-architecture.md) | [Table of Contents](./00-index.md#table-of-contents) | [5. Orchestration →](./05-capability-orchestration.md) |

---

*End of Section 4 — RFC-PLATARCH-0001*
