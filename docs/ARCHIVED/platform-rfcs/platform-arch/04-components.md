```
RFC-PLATARCH-0001                                              Section 4
Category: Standards Track                      Binary Component Categorization
```

# 4. Binary Component Categorization

[← Architecture](./03-architecture.md) | [Index](./00-index.md#table-of-contents) | [Next: Orchestration →](./05-capability-orchestration.md)

---

## 4.1 Overview

This section defines the binary categorization of components within the platform. Components are classified into exactly two categories based on a single criterion: whether the base chart depends on capabilities they provide. This binary classification determines base chart usage and prevents circular dependencies in the platform architecture.

---

## 2. The Binary Classification

### 2.1 Two Categories

The platform recognizes exactly two component categories:

| Category | Base Chart Usage | Criterion |
|----------|------------------|-----------|
| Infrastructure Provider | MUST NOT use base chart | Provides capabilities consumed by base chart templates |
| Platform Consumer | MUST use base chart | Consumes capabilities; does not provide capabilities to base chart |

There are no intermediate categories. Every component falls into exactly one category. The classification is binary and deterministic.

### 2.2 The Decision Test

A single question determines component classification:

**Does this component PROVIDE a capability that base chart templates consume?**

- **YES** → Infrastructure Provider (no base chart)
- **NO** → Platform Consumer (must use base chart)

This test is absolute. There are no edge cases, no exceptions, and no special circumstances that change the classification logic.

### 2.3 What the Binary Test Is NOT About

The binary classification is NOT about:
- Whether a component provides capabilities (both categories can provide capabilities)
- Whether a component consumes capabilities (both categories can consume capabilities)
- Whether a component is "infrastructure" or "application"

Many components both provide AND consume capabilities. The binary test is specifically about whether **base chart templates** consume the component's provided capability.

| Component | Provides Capabilities? | Consumes Capabilities? | Base Chart Uses It? | Classification |
|-----------|----------------------|----------------------|---------------------|----------------|
| Keycloak | Yes (OIDC, clients) | Yes (PostgreSQL) | Yes | Infrastructure Provider |
| Backstage | Yes (dev portal) | Yes (PostgreSQL, OIDC) | No | Platform Consumer |
| cert-manager | Yes (certificates) | No | Yes | Infrastructure Provider |
| Tenant App | Maybe | Yes | No | Platform Consumer |

### 2.4 Why Binary Classification

Binary classification exists to prevent circular dependencies. Base chart templates consume capabilities from Infrastructure Providers. If an Infrastructure Provider used the base chart, it would depend on itself—a circular dependency.

The binary test ensures architectural soundness. Components that provide capabilities consumed by base chart templates cannot use the base chart. Components that do not provide capabilities to base chart must use the base chart. There is no middle ground.

---

## 3. Infrastructure Providers

### 3.1 Definition

An Infrastructure Provider is a component that provides capabilities consumed by base chart templates. Infrastructure Providers enable the platform to function. They are prerequisites for Platform Consumers.

### 3.2 Classification Criterion

A component is an Infrastructure Provider if and only if:

**The base chart contains templates that consume a capability this component provides.**

Examples of capabilities base chart templates consume:
- Certificate generation (cert-manager)
- Secret injection (External Secrets Operator, Vault)
- Database provisioning (Zalando PostgreSQL Operator)
- Message queue provisioning (Strimzi)
- Identity management (Keycloak)
- Resource provisioning (Crossplane)
- Ingress routing (ingress-nginx)
- Load balancing (MetalLB)
- Storage provisioning (Rook-Ceph)
- GitOps deployment (ArgoCD)

### 3.3 Infrastructure Provider Inventory

| Component | Capability Provided | Why Infrastructure Provider |
|-----------|--------------------|-----------------------------|
| cert-manager | Certificate CRD | Base chart Certificate templates consume cert-manager |
| External Secrets Operator | ExternalSecret CRD | Base chart ExternalSecret templates consume ESO |
| Vault | Secret backend | ESO uses Vault; base chart secrets flow through this chain |
| Crossplane | XRD claims | Base chart Crossplane claim templates consume Crossplane |
| Keycloak | OIDC provider, Client CRD | Base chart Keycloak client templates consume Keycloak |
| Zalando PostgreSQL Operator | PostgreSQL CRD | Base chart database claim templates consume Zalando |
| Strimzi | KafkaTopic CRD | Base chart Kafka topic templates consume Strimzi |
| Rook-Ceph | StorageClass | Base chart PVC templates may consume Rook storage classes |
| MetalLB | LoadBalancer | Base chart Service templates may consume MetalLB |
| ingress-nginx | IngressClass | Base chart Ingress templates consume ingress-nginx |
| ArgoCD | Application CRD | Platform deploys apps through ArgoCD Applications |

### 3.4 Infrastructure Providers May Consume Capabilities

Infrastructure Providers may consume capabilities from other Infrastructure Providers. The binary classification is about what a component PROVIDES to the base chart, not what it CONSUMES.

**Example: Keycloak**
- Keycloak PROVIDES: OIDC authentication, Keycloak client CRD capability
- Keycloak CONSUMES: PostgreSQL database, certificates, secrets
- Classification: **Infrastructure Provider** (because base chart Keycloak client templates consume Keycloak)
- Keycloak's PostgreSQL dependency is configured in Keycloak's upstream chart, not through base chart

**Example: External Secrets Operator**
- ESO PROVIDES: ExternalSecret CRD capability
- ESO CONSUMES: Vault connectivity
- Classification: **Infrastructure Provider** (because base chart ExternalSecret templates consume ESO)

Infrastructure Providers that consume capabilities:
- Configure dependencies directly in their upstream Helm charts
- Do NOT use base chart for capability consumption
- Still participate in DAG-based capability resolution
- Wait for required capabilities before deployment (just like Platform Consumers)

### 3.6 Characteristics

Infrastructure Providers:
- Use upstream Helm charts directly (no platform-base dependency)
- Are owned by the platform team
- Provide capabilities through CRDs, controllers, or services
- May consume capabilities from other Infrastructure Providers (configured directly, not via base chart)
- Deploy based on DAG capability resolution
- Have cluster-wide or platform-wide scope

### 3.7 Management Rules

Infrastructure Providers:
- MUST be owned by the platform team
- MUST use upstream charts directly (no base chart)
- MUST publish capability contracts
- MUST be deployed through GitOps
- MUST have documented upgrade procedures
- MUST NOT depend on the base chart (circular dependency)

---

## 4. Platform Consumers

### 4.1 Definition

A Platform Consumer is a component that consumes capabilities provided by Infrastructure Providers and does not provide capabilities consumed by base chart templates. Platform Consumers integrate with the platform through the canonical base chart.

### 4.2 Classification Criterion

A component is a Platform Consumer if and only if:

**The base chart does NOT contain templates that consume a capability this component provides.**

A Platform Consumer may provide capabilities to other Platform Consumers. The criterion is specifically about base chart template consumption.

### 4.3 Platform Consumer Inventory

| Component | Capabilities Consumed | Why Platform Consumer |
|-----------|----------------------|----------------------|
| Backstage | Database, Keycloak OIDC, Secrets | Base chart does not depend on Backstage |
| Harbor | Database, Secrets, Certificates | Base chart does not depend on Harbor |
| Grafana | Secrets, Certificates | Base chart does not depend on Grafana |
| Loki | Storage, Secrets | Base chart does not depend on Loki |
| Tempo | Storage, Secrets | Base chart does not depend on Tempo |
| Tenant Applications | Various platform capabilities | Base chart does not depend on tenant apps |

### 4.4 Tenant Applications

Tenant applications are a subset of Platform Consumers. They are business workloads deployed by application teams that consume platform capabilities.

Tenant applications:
- Are owned by application teams (not platform team)
- Use the base chart like all Platform Consumers
- Consume capabilities from Infrastructure Providers
- May provide capabilities to other tenant applications
- Have namespace-scoped isolation

The distinction between platform-owned Platform Consumers (Backstage, Harbor, Grafana) and tenant applications is ownership, not categorization. Both are Platform Consumers. Both must use the base chart.

### 4.5 Characteristics

Platform Consumers:
- Use the canonical base chart (platform-base as Helm dependency)
- May be owned by platform team or application teams
- Consume capabilities through base chart templates
- Deploy based on DAG capability resolution
- Have namespace-scoped isolation

### 4.6 Management Rules

Platform Consumers:
- MUST use the canonical base chart
- MUST declare all capability requirements
- MUST declare all capability provisions
- MUST use platform secret management (via base chart)
- MUST use platform identity (via base chart)
- MUST comply with platform security policies
- MUST NOT create CRDs (that would make them Infrastructure Providers)
- MUST NOT install operators (that would make them Infrastructure Providers)

---

## 5. The Canonical Base Chart

### 5.1 Purpose

The base chart is a Helm library chart used exclusively by Platform Consumers. It provides templates that integrate Platform Consumers with Infrastructure Providers.

The base chart exists because:

**Uniformity:** Every Platform Consumer integrates the same way. Integration behavior is predictable.

**Completeness:** The base chart embeds all required integrations. Platform Consumers cannot skip integration points.

**Evolvability:** Platform changes are delivered through the base chart. All Platform Consumers receive changes.

**Governance:** The base chart enforces governance. Platform Consumers cannot bypass governance.

### 5.2 Base Chart Scope

The base chart provides templates that consume capabilities from Infrastructure Providers:

| Template Category | Infrastructure Provider Consumed |
|-------------------|----------------------------------|
| ExternalSecret templates | External Secrets Operator, Vault |
| Certificate templates | cert-manager |
| Keycloak client templates | Keycloak |
| Database claim templates | Crossplane, Zalando PostgreSQL Operator |
| Kafka topic templates | Strimzi |
| Storage claim templates | Rook-Ceph |
| Ingress templates | ingress-nginx |
| Service templates | MetalLB |

This scope defines the boundary. Infrastructure Providers in this table cannot use the base chart—doing so would create circular dependencies.

### 5.3 Why Infrastructure Providers Cannot Use Base Chart

If cert-manager used the base chart, and the base chart contains Certificate templates that consume cert-manager, cert-manager would depend on itself. This is a circular dependency.

The binary categorization prevents this: any component whose capability is consumed by base chart templates is an Infrastructure Provider and cannot use the base chart.

### 5.4 Base Chart Versioning

The base chart is versioned using semantic versioning:

**Major version:** Breaking changes requiring Platform Consumer modification.

**Minor version:** New features with backward compatibility.

**Patch version:** Bug fixes with full backward compatibility.

Platform Consumers specify the base chart version they use. Upgrades are coordinated platform events.

### 5.5 Base Chart Evolution

When a new Infrastructure Provider is added to the platform:

1. The Infrastructure Provider is deployed (without base chart)
2. The Infrastructure Provider becomes available
3. Base chart is updated with templates consuming the new capability
4. Platform Consumers can use the new capability through base chart

The base chart grows as Infrastructure Providers are added. New templates are added only after the corresponding Infrastructure Provider is operational.

---

## 6. Shared Infrastructure Model

### 6.1 Infrastructure Operators vs Instances

Many Infrastructure Providers are operators that manage instances:

| Operator (Infrastructure Provider) | Managed Instances |
|------------------------------------|-------------------|
| Zalando PostgreSQL Operator | PostgreSQL clusters |
| Strimzi | Kafka clusters |
| Rook-Ceph | Ceph clusters |
| Crossplane | Cloud resources |

The operator is an Infrastructure Provider (cannot use base chart). The instances it manages are provisioned through base chart claims when Platform Consumers request them.

### 6.2 Capability Provisioning Flow

1. Platform Consumer declares capability requirement (e.g., PostgreSQL database)
2. Base chart template generates claim (e.g., Crossplane XR claim or Zalando PostgreSQL CR)
3. Infrastructure Provider operator processes claim
4. Instance is provisioned
5. Platform Consumer receives connection details

This flow maintains the binary categorization: Platform Consumers use base chart claims; Infrastructure Providers process those claims.

### 6.3 Eligibility for Shared Status

Infrastructure is eligible for shared status when:

- Multiple Platform Consumers require the same capability
- The infrastructure requires specialized operational expertise
- Per-consumer deployment would create unjustified duplication
- The infrastructure can be meaningfully isolated between consumers
- Platform team can commit to required guarantees

Shared infrastructure operators are Infrastructure Providers. They are platform-owned and platform-operated.

---

## 7. Mandatory Guarantees

### 7.1 Infrastructure Provider Guarantees

Infrastructure Providers MUST provide:

**Availability:** Defined uptime targets documented in capability contracts.

**Stability:** Stable CRD schemas and API contracts with versioned evolution.

**Upgrade Path:** Documented upgrade procedures without consumer disruption.

### 7.2 Platform Consumer Guarantees

Platform Consumers receive:

**Capability Access:** Access to all declared capabilities when satisfied.

**Isolation:** Namespace-scoped isolation from other Platform Consumers.

**Identity:** Platform-assigned identity for authentication and authorization.

### 7.3 Backup and Recovery

Shared infrastructure (managed by Infrastructure Provider operators) MUST provide:

- Backup frequency and retention
- Recovery procedures
- Recovery time objectives
- Data durability guarantees

---

## 8. Ownership Boundaries

### 8.1 Platform Team Ownership

The platform team owns:
- All Infrastructure Providers
- Platform-owned Platform Consumers (Backstage, Harbor, Grafana, observability stack)
- The canonical base chart
- Platform governance policies

### 8.2 Application Team Ownership

Application teams own:
- Their tenant applications (which are Platform Consumers)
- Application-specific configurations within base chart constraints

### 8.3 Ownership Rules

- Infrastructure Providers are always platform-owned
- Platform Consumers may be platform-owned or application-owned
- Ownership determines modification authority
- Cross-boundary modification is prohibited

---

## 9. Summary

### 9.1 Binary Categories

| Category | Base Chart | Ownership | Examples |
|----------|------------|-----------|----------|
| Infrastructure Provider | MUST NOT use | Platform team | cert-manager, Crossplane, Vault, ESO, Keycloak, Zalando, Strimzi, Rook-Ceph, MetalLB, ingress-nginx, ArgoCD |
| Platform Consumer | MUST use | Platform or Application team | Backstage, Harbor, Grafana, Loki, Tempo, tenant applications |

### 9.2 The Binary Test

**Does this component PROVIDE a capability that base chart templates consume?**
- YES → Infrastructure Provider (cannot use base chart)
- NO → Platform Consumer (must use base chart)

Note: Both categories may provide AND consume capabilities. The test is specifically about base chart template consumption.

### 9.3 Key Rules

| Rule | Infrastructure Provider | Platform Consumer |
|------|------------------------|-------------------|
| Base chart usage | Prohibited | Required |
| Upstream chart | Required | Via base chart |
| Capability provision to base chart | Yes | No |
| Platform team ownership | Required | Optional |
| CRD creation | Permitted | Prohibited |

### 9.4 Why This Matters

Binary categorization prevents circular dependencies. If a component provides capabilities to the base chart, it cannot use the base chart. This architectural constraint is non-negotiable.

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 3. Architecture](./03-architecture.md) | [Table of Contents](./00-index.md#table-of-contents) | [5. Orchestration →](./05-capability-orchestration.md) |

---

*End of Section 4 — RFC-PLATARCH-0001*
