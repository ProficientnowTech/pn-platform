```
RFC-PLATARCH-0001                                              Section 6
Category: Standards Track                         Shared Infrastructure
```

# 6. Shared Infrastructure

[← Orchestration](./05-capability-orchestration.md) | [Index](./00-index.md#table-of-contents) | [Next: Application Model →](./07-application-model.md)

---

## 6.1 Overview

This section defines the shared infrastructure model. It covers capability contracts, ownership and lifecycle rules, consumer relationships, and explicit anti-patterns. Shared infrastructure is the platform's mechanism for providing common services efficiently while maintaining governance.

In terms of binary categorization:
- **Infrastructure operators** (Zalando PostgreSQL Operator, Strimzi, Rook-Ceph, etc.) are **Infrastructure Providers**—they cannot use the base chart
- **Operator-managed instances** (databases, topics, storage) are provisioned through base chart claims when **Platform Consumers** request them
- **Platform Consumers** declare capability requirements; the base chart generates claims that Infrastructure Provider operators fulfill

---

## 2. Capability Contracts

### 2.1 What Is a Capability Contract

A capability contract is the formal agreement between a capability provider and its consumers. The contract specifies what the capability provides, what guarantees it offers, and what consumers must do to use it correctly.

Contracts are binding. Providers MUST fulfill contract terms. Consumers MUST use capabilities according to contract terms. Violations are failures.

### 2.2 Contract Contents

A capability contract contains:

**Interface Specification:**
- Access method (connection string, API endpoint, etc.)
- Authentication requirements
- Protocol and data format
- Operation semantics

**Guarantee Specification:**
- Availability target (e.g., 99.9%)
- Durability guarantee (e.g., no data loss after acknowledgment)
- Performance characteristics (e.g., latency bounds)
- Consistency model (e.g., eventual, strong)

**Constraint Specification:**
- Usage limits (e.g., connections, throughput)
- Tenant isolation (e.g., schema separation, namespace separation)
- Supported operations (e.g., read/write, admin operations)

**Lifecycle Specification:**
- Version compatibility rules
- Deprecation policy
- Migration support

### 2.3 Contract Stability

Contracts MUST be stable. Once published, a contract MUST NOT change in ways that break existing consumers.

Stable changes (permitted without new major version):
- Adding optional capabilities
- Relaxing constraints
- Improving guarantees

Breaking changes (require new major version):
- Removing capabilities
- Adding required parameters
- Tightening constraints
- Reducing guarantees

### 2.4 Contract Versioning

Contracts are versioned semantically:

**Major version (X.0.0):** Breaking changes. Consumers must update integration.

**Minor version (x.Y.0):** New features, backward compatible. Consumers may use without changes.

**Patch version (x.y.Z):** Bug fixes, fully compatible. Transparent to consumers.

Version compatibility rules:
- Consumer requiring 2.3.0 is satisfied by provider offering 2.3.0, 2.3.1, 2.4.0, etc.
- Consumer requiring 2.3.0 is NOT satisfied by provider offering 3.0.0
- Consumer requiring 2.3.0 is NOT satisfied by provider offering 2.2.0

### 2.5 Contract Monotonicity

Guarantees in contracts are monotonic within a major version. Guarantees may be maintained or improved. Guarantees may not be degraded.

Monotonicity protects consumers. Consumers who designed for a guarantee do not need to redesign when the guarantee improves. Degraded guarantees would break consumers silently.

### 2.6 Contract Publication

Contracts MUST be published and discoverable. Publication includes:
- Contract document in versioned location
- Machine-readable contract specification
- Example usage
- Migration guides for version upgrades

Unpublished contracts do not exist. Consumers cannot integrate with undocumented capabilities.

---

## 3. Ownership and Lifecycle Rules

### 3.1 Platform Ownership

Shared infrastructure is owned by the platform team. This ownership is non-negotiable. Applications consume shared infrastructure; they do not own it.

Platform ownership means the platform team:
- Makes architectural decisions
- Performs maintenance and upgrades
- Manages capacity
- Handles incidents
- Controls lifecycle

### 3.2 Consumer Relationship

Platform Consumers are consumers of shared infrastructure. The consumer relationship means:

**Access rights:** Platform Consumers may access capabilities according to contracts.

**No modification rights:** Platform Consumers may not modify infrastructure.

**No ownership transfer:** Consumption does not confer ownership.

**Bound by contract:** Platform Consumers must use capabilities according to contract terms.

**Base chart integration:** Platform Consumers declare capability requirements through the base chart. The base chart generates claims (Crossplane XR, PostgreSQL CR, etc.) that Infrastructure Provider operators process.

### 3.3 Lifecycle Independence

Shared infrastructure lifecycle is independent of any single application:

**Creation:** Infrastructure is created when the platform provisions it, not when an application first uses it.

**Operation:** Infrastructure continues operating regardless of which applications are using it.

**Removal:** Infrastructure is removed through platform decommissioning process, not through application removal.

Lifecycle independence ensures infrastructure stability. Applications come and go. Infrastructure persists.

### 3.4 Decommissioning Rules

Shared infrastructure decommissioning requires:

1. **Consumer verification:** No active consumers exist, or all consumers have migrated.

2. **Deprecation period:** Consumers have been notified and given time to migrate.

3. **Data handling:** All data has been migrated, archived, or deleted according to policy.

4. **Audit trail:** Decommissioning is documented for compliance.

Decommissioning is a deliberate process. Infrastructure does not disappear accidentally.

### 3.5 No Consumer-Driven Removal

Applications MUST NOT cause infrastructure removal. If application A is the last consumer of infrastructure X, removing application A does not remove infrastructure X.

This rule prevents accidental infrastructure loss. Even with one consumer, the infrastructure remains platform-owned. Removal decisions are platform decisions.

---

## 4. Consumer Boundaries

### 4.1 What Consumers May Do

Consumers MAY:
- Access capabilities through defined interfaces
- Store data within their tenant boundaries
- Use operations permitted by contracts
- Request capability modifications through platform processes

### 4.2 What Consumers May NOT Do

Consumers MUST NOT:
- Directly access infrastructure internals
- Modify infrastructure configuration
- Access other consumers' data
- Exceed contract-defined limits
- Bypass capability interfaces

### 4.3 Tenant Isolation

Consumers are isolated from each other within shared infrastructure:

**Data isolation:** Each consumer's data is separated from other consumers' data.

**Access isolation:** Consumers cannot access other consumers' resources.

**Performance isolation:** One consumer's usage should not degrade other consumers' experience.

Isolation mechanisms vary by infrastructure type (schemas, namespaces, quotas, etc.).

### 4.4 Consumer Responsibilities

Consumers are responsible for:

**Correct usage:** Using capabilities according to contracts.

**Data management:** Managing their data within infrastructure constraints.

**Capacity coordination:** Working with platform for capacity needs beyond default allocations.

**Migration:** Migrating when capabilities are deprecated.

---

## 5. Infrastructure Categories

### 5.1 Data Services

Data services store and retrieve data for applications:

**Relational databases:** PostgreSQL, MySQL for structured data with SQL interface.

**Document databases:** MongoDB for flexible schema data.

**Key-value stores:** Redis for caching and session data.

**Object storage:** S3-compatible storage for unstructured data.

Data service contracts include data model constraints, consistency guarantees, and backup provisions.

### 5.2 Messaging Services

Messaging services enable asynchronous communication:

**Message queues:** RabbitMQ for traditional queue semantics.

**Event streams:** Kafka for event sourcing and stream processing.

**Pub/sub:** Event-driven communication patterns.

Messaging service contracts include delivery guarantees, ordering guarantees, and retention policies.

### 5.3 Security Services

Security services provide authentication, authorization, and secret management. These are Infrastructure Providers—they cannot use the base chart because base chart templates consume their capabilities:

**Identity providers:** Keycloak for authentication and federation. Base chart Keycloak client templates consume Keycloak.

**Secret management:** Vault and External Secrets Operator for secret storage and injection. Base chart ExternalSecret templates consume ESO.

**Certificate management:** cert-manager for TLS certificate lifecycle. Base chart Certificate templates consume cert-manager.

Security service contracts include authentication protocols, secret rotation policies, and certificate issuance procedures.

### 5.4 Integration Services

Integration services enable service-to-service communication:

**API gateways:** Ingress controllers for external access.

**Service mesh:** Istio or Linkerd for internal service communication.

**Event buses:** Platform-wide event distribution.

Integration service contracts include routing rules, rate limiting policies, and observability integration.

---

## 6. Explicit Anti-Patterns

### 6.1 Anti-Pattern: Per-Application Databases

Provisioning a separate database instance for each application is prohibited when shared database infrastructure exists.

**Problem:** Per-application databases duplicate operational burden, fragment data management, and prevent platform-level optimization.

**Solution:** Applications use shared database infrastructure through capability contracts. Tenant isolation is achieved through schemas or databases within shared infrastructure.

### 6.2 Anti-Pattern: Embedded Infrastructure

Including infrastructure components (databases, queues) within application deployments is prohibited.

**Problem:** Embedded infrastructure is not managed by platform processes. Backups, upgrades, and monitoring are absent. Failures may go undetected.

**Solution:** Applications declare infrastructure requirements. Platform provisions infrastructure through shared infrastructure. Applications consume capabilities.

### 6.3 Anti-Pattern: Platform Consumer-Owned Operators

Platform Consumers installing and managing operators that provide shared services is prohibited.

**Problem:** Multiple operators for the same service create conflicts. Operators require elevated permissions that Platform Consumers should not have. Operator lifecycle becomes entangled with Platform Consumer lifecycle. Installing an operator would make the Platform Consumer an Infrastructure Provider—breaking the binary categorization.

**Solution:** Operators are Infrastructure Providers, platform-owned. Platform Consumers request capabilities through base chart. Platform provisions through platform-managed operators.

### 6.4 Anti-Pattern: Direct Infrastructure Access

Applications directly accessing infrastructure internals (bypassing capability interfaces) is prohibited.

**Problem:** Direct access bypasses contracts. Contract guarantees do not apply. Upgrades may break direct access. Security boundaries may be violated.

**Solution:** Applications access infrastructure only through defined capability interfaces. Interfaces abstract infrastructure details.

### 6.5 Anti-Pattern: Shadow Infrastructure

Running infrastructure outside platform governance (e.g., cloud services accessed directly by applications) is prohibited.

**Problem:** Shadow infrastructure bypasses platform security, monitoring, and governance. Shadow infrastructure is invisible to platform operations.

**Solution:** All infrastructure consumed by platform applications must be platform-provisioned or explicitly approved. External services require formal integration.

### 6.6 Anti-Pattern: Capability Hoarding

Requesting more infrastructure capacity than needed is prohibited.

**Problem:** Hoarded capacity is unavailable to other applications. Hoarding wastes resources. Hoarding encourages per-application thinking.

**Solution:** Applications request capacity based on actual needs. Platform manages capacity pool. Capacity is allocated based on demonstrated need.

---

## 7. Guarantee Fulfillment

### 7.1 Availability Commitments

Shared infrastructure MUST provide defined availability levels:

**Target specification:** Availability is expressed as a percentage (e.g., 99.9%).

**Measurement method:** How availability is measured (e.g., successful requests / total requests).

**Exclusions:** What is excluded from measurement (e.g., planned maintenance windows).

**Consequences:** What happens when targets are missed (notification, remediation priority).

### 7.2 Durability Commitments

Shared infrastructure that stores data MUST provide durability guarantees:

**Durability level:** Probability of data preservation (e.g., 99.999999999%).

**Failure coverage:** What failure scenarios are covered (node failure, disk failure, AZ failure).

**Acknowledgment semantics:** When data is considered durable (after acknowledgment).

### 7.3 Backup Commitments

Shared infrastructure MUST provide backup capability:

**Backup frequency:** How often backups occur.

**Backup retention:** How long backups are kept.

**Recovery procedures:** How to restore from backup.

**Recovery time objective (RTO):** How long recovery takes.

**Recovery point objective (RPO):** How much data may be lost.

### 7.4 Upgrade Commitments

Shared infrastructure MUST support seamless upgrades:

**Zero-downtime upgrades:** Consumers do not experience outage during upgrade.

**Compatibility maintenance:** Upgrades do not break consumer integration within major version.

**Notification:** Consumers are notified of upcoming upgrades that might affect them.

---

## 8. Summary

### 8.1 Capability Contracts

| Element | Description |
|---------|-------------|
| Interface | How to access the capability |
| Guarantees | What the capability promises |
| Constraints | What limits apply |
| Versioning | How contracts evolve |

### 8.2 Ownership Model

| Aspect | Owner |
|--------|-------|
| Infrastructure | Platform team |
| Data in infrastructure | Application team |
| Contract definition | Platform team |
| Capacity allocation | Platform team |

### 8.3 Consumer Rules

| Permitted | Prohibited |
|-----------|------------|
| Access through interfaces | Direct infrastructure access |
| Store data in tenant boundary | Access other tenants' data |
| Request capacity increases | Hoard capacity |
| Use contract-defined operations | Bypass contracts |

### 8.4 Anti-Patterns

| Pattern | Problem | Solution |
|---------|---------|----------|
| Per-app databases | Duplication, fragmentation | Shared infrastructure |
| Embedded infrastructure | No governance | Capability consumption |
| Application operators | Conflicts, permissions | Platform operators |
| Shadow infrastructure | Invisible, ungoverned | Platform provisioning |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 5. Orchestration](./05-capability-orchestration.md) | [Table of Contents](./00-index.md#table-of-contents) | [7. Application Model →](./07-application-model.md) |

---

*End of Section 6 — RFC-PLATARCH-0001*
