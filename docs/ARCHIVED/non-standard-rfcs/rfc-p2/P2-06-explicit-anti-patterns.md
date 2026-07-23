# RFC-P2-06 — Explicit Anti-Patterns

**Status:** Draft
**Audience:** Platform Engineers, Architects, Operations Teams

---

## 1. Introduction

This document enumerates patterns that are explicitly forbidden in the context of shared infrastructure. Each anti-pattern represents a structural violation of the principles established in RFC-P2. For each forbidden pattern, this document explains why the pattern occurs, why it is harmful, and why it is forbidden. This document exists to prevent regression and entropy accumulation.

---

## 2. The Purpose of Anti-Pattern Documentation

### 2.1 Prevention Over Remediation

Documenting anti-patterns prevents their introduction. Engineers who understand why patterns are forbidden avoid implementing them. Prevention is less costly than remediation.

Once an anti-pattern is implemented, removing it requires effort. Dependencies form. Workflows develop around it. Remediation disrupts operations. Preventing introduction eliminates remediation cost entirely.

### 2.2 Explicit Boundaries

Anti-pattern documentation establishes explicit boundaries. The boundary between acceptable and unacceptable is clear. There is no ambiguity about whether a pattern is permitted.

Ambiguous boundaries produce boundary violations. When engineers are unsure whether a pattern is acceptable, some will implement it. Explicit boundaries eliminate uncertainty.

### 2.3 Institutional Memory

Anti-pattern documentation preserves institutional memory. Patterns are forbidden for reasons. Those reasons may be forgotten as teams change. Documentation preserves the reasoning.

Forgotten reasoning leads to repeated mistakes. Teams that do not know why a pattern is forbidden may reintroduce it. Documentation prevents this recurrence.

---

## 3. Anti-Pattern: Per-Application Databases

### 3.1 Description

Per-application databases are database instances deployed, owned, and operated by individual applications rather than provided as shared platform infrastructure.

This pattern manifests as database containers within application deployments, database operators deployed per-application, or database instances provisioned through application-controlled processes.

### 3.2 Why It Occurs

Per-application databases occur because:

**Perceived Autonomy:** Teams believe they need control over their database. They want to choose versions, configure settings, and manage upgrades independently.

**Speed of Initial Deployment:** Deploying a database with an application is faster than requesting shared infrastructure. The team avoids coordination overhead.

**Isolation Assumptions:** Teams assume they need isolated databases. They believe shared databases would expose them to other applications' problems.

**Historical Practice:** Teams have always deployed their own databases. The pattern persists because it is familiar.

**Capability Gaps:** Shared database infrastructure may not exist or may not meet specific needs. Teams fill gaps by deploying their own.

### 3.3 Why It Is Harmful

Per-application databases cause harm because:

**Operational Burden Distribution:** Each database requires backup, monitoring, patching, and upgrade management. This burden is distributed across every team that deploys a database. Aggregate burden exceeds what centralized management would require.

**Expertise Dilution:** No team develops deep database expertise. Every team has shallow knowledge. Problems that require deep expertise go unresolved or are resolved poorly.

**Inconsistent Guarantees:** Each database has different availability, durability, and recovery characteristics. Platform-wide guarantees are impossible because each database is different.

**Resource Waste:** Each database consumes compute and storage. Databases that could share infrastructure instead duplicate it. Resource utilization is poor.

**Security Inconsistency:** Each database has independent security configuration. Security posture varies. Vulnerabilities accumulate across instances without centralized visibility.

**Capability Model Violation:** Per-application databases are not registered as capability providers. The orchestrator cannot track dependencies. The dependency graph is incomplete.

### 3.4 Why It Is Forbidden

Per-application databases are forbidden because they maximize entropy. RFC-P2-01 established that per-application infrastructure produces proliferation, drift, knowledge fragmentation, and inconsistency. Per-application databases exhibit all these problems.

Per-application databases violate ownership rules. RFC-P2-05 established that the platform owns shared infrastructure. When applications own databases, ownership is distributed. Distributed ownership produces the accountability gaps RFC-P2-05 prohibits.

Per-application databases break determinism. RFC-P1 established that the orchestration system requires explicit dependencies. Per-application databases hide infrastructure within applications, making dependencies invisible to the orchestrator.

---

## 4. Anti-Pattern: Embedded Infrastructure Inside Application Charts

### 4.1 Description

Embedded infrastructure inside application charts is infrastructure defined within the same deployment artifact as the application that uses it. The application deployment includes database definitions, message queue definitions, cache definitions, or other infrastructure components.

This pattern manifests as infrastructure resources in application Helm charts, Kustomize overlays that include infrastructure, or application repositories that contain infrastructure manifests.

### 4.2 Why It Occurs

Embedded infrastructure occurs because:

**Deployment Convenience:** Deploying infrastructure with the application ensures both arrive together. The team avoids coordination with platform teams.

**Testing Simplicity:** Embedded infrastructure enables self-contained testing. The application and its infrastructure can be tested together in isolation.

**Version Coupling:** Teams want infrastructure versions coupled to application versions. Embedding ensures the infrastructure version matches what the application expects.

**Perceived Completeness:** Teams view their application as incomplete without its infrastructure. Embedding produces a "complete" deployment artifact.

**Template Proliferation:** Starter templates and scaffolding include embedded infrastructure. Teams inherit the pattern from templates.

### 4.3 Why It Is Harmful

Embedded infrastructure causes harm because:

**Lifecycle Coupling:** Infrastructure lifecycle becomes coupled to application lifecycle. Deleting the application deletes the infrastructure. Upgrading the application may disrupt the infrastructure. The lifecycles that should be independent are entangled.

**Ownership Confusion:** Who owns embedded infrastructure? The application team deployed it, but it may serve platform functions. Ownership is ambiguous. RFC-P2-05 prohibits ambiguous ownership.

**Invisible Infrastructure:** Embedded infrastructure is not visible to platform inventory. The platform does not know what infrastructure exists. Capacity planning, security scanning, and compliance auditing miss embedded infrastructure.

**Duplicate Infrastructure:** Multiple applications may embed similar infrastructure. Each embedding is independent. Consolidation opportunities are invisible.

**Capability Hiding:** Embedded infrastructure provides capabilities that are not exposed to the platform model. Other applications cannot depend on capabilities hidden within applications.

**Configuration Drift:** Embedded infrastructure configurations drift independently. There is no baseline. There is no enforcement. Each embedding evolves separately.

### 4.4 Why It Is Forbidden

Embedded infrastructure is forbidden because it hides infrastructure from platform governance. RFC-P2-02 requires that infrastructure meeting eligibility criteria be centralized. Embedded infrastructure evades this requirement by not being visible.

Embedded infrastructure is forbidden because it violates ownership boundaries. RFC-P2-05 establishes that applications consume infrastructure; they do not own it. Embedded infrastructure places ownership within applications.

Embedded infrastructure is forbidden because it breaks the capability model. RFC-P1-04 requires capabilities to target named resources. Embedded infrastructure has no platform-visible identity. It cannot be a capability provider.

---

## 5. Anti-Pattern: Application-Owned Operators for Shared Services

### 5.1 Description

Application-owned operators for shared services are Kubernetes operators deployed by applications to manage infrastructure that serves multiple consumers or platform functions.

This pattern manifests as database operators deployed per-application, certificate management operators within application namespaces, or service mesh control planes owned by applications.

### 5.2 Why It Occurs

Application-owned operators occur because:

**Operational Familiarity:** Teams are familiar with specific operators. They deploy what they know rather than learning platform-provided alternatives.

**Feature Requirements:** Teams need operator features not available in platform-provided infrastructure. They deploy operators to access those features.

**Version Requirements:** Teams need specific operator versions. Platform-provided versions may lag. Teams deploy their own to get current versions.

**Perceived Control:** Teams believe they need operational control. Deploying their own operator gives them that control.

**Gap Filling:** Platform-provided capability does not exist. Teams fill the gap by deploying operators themselves.

### 5.3 Why It Is Harmful

Application-owned operators cause harm because:

**Cluster-Wide Impact:** Operators often have cluster-wide effects. An application-owned operator may affect resources beyond the application's scope. Application teams do not have the authority to affect cluster-wide state.

**Conflicting Controllers:** Multiple operators managing the same resource types conflict. One operator's reconciliation may undo another's. The result is unstable state and reconciliation loops.

**Privilege Escalation:** Operators require elevated privileges. Application-owned operators grant elevated privileges to application deployments. This violates least-privilege principles.

**Resource Contention:** Operators consume cluster resources for control loops. Multiple operators consume more resources than a single shared operator would.

**Upgrade Complexity:** Each operator must be upgraded independently. Operator upgrades may have cluster-wide effects. Coordinating independent operator upgrades is complex.

**Accountability Gaps:** When an operator misbehaves, accountability is unclear. The application team deployed it, but its effects are cluster-wide. Who is responsible?

### 5.4 Why It Is Forbidden

Application-owned operators are forbidden because they violate ownership boundaries. RFC-P2-05 establishes that applications do not own shared infrastructure. Operators that manage shared services are shared infrastructure. Applications must not own them.

Application-owned operators are forbidden because they create authority confusion. RFC-P2-05 establishes that the platform has exclusive authority to modify shared infrastructure. Application-owned operators modify infrastructure under application control, not platform control.

Application-owned operators are forbidden because they undermine platform guarantees. RFC-P2-03 requires the platform to provide guarantees. The platform cannot guarantee infrastructure controlled by application-owned operators.

---

## 6. Anti-Pattern: Hidden Infrastructure Dependencies

### 6.1 Description

Hidden infrastructure dependencies are dependencies on infrastructure that are not declared in the capability model. The application depends on infrastructure, but this dependency is not visible to the orchestrator.

This pattern manifests as hardcoded connection strings, environment variables referencing undeclared infrastructure, configuration files pointing to infrastructure not in the dependency graph, or assumptions about infrastructure existence without declaration.

### 6.2 Why It Occurs

Hidden infrastructure dependencies occur because:

**Convenience:** Declaring dependencies requires effort. Hardcoding is faster. Teams take shortcuts.

**Legacy Integration:** Legacy applications were not designed for capability models. Their dependencies are baked into code and configuration.

**Documentation Gaps:** Teams do not know what dependencies their applications have. Undiscovered dependencies cannot be declared.

**Testing Assumptions:** Applications are tested in environments where infrastructure exists. The dependency is satisfied by environment setup, not by declaration.

**Implicit Knowledge:** Teams know their applications need certain infrastructure. The knowledge exists in people, not in declarations.

### 6.3 Why It Is Harmful

Hidden infrastructure dependencies cause harm because:

**Orchestration Failure:** The orchestrator cannot enforce ordering for undeclared dependencies. Applications may be deployed before their dependencies are ready. Deployments fail or produce incorrect state.

**Deployment Non-Determinism:** Deployments succeed or fail depending on whether infrastructure happens to exist. The same deployment may succeed in one environment and fail in another. Determinism is broken.

**Impact Analysis Impossibility:** When infrastructure changes, impact cannot be analyzed. There is no record of what depends on the infrastructure. Changes may break applications without warning.

**Recovery Incompleteness:** When recovering from failures, undeclared dependencies may be missed. Infrastructure may be restored while dependent applications remain broken.

**Audit Failure:** Compliance audits require understanding dependencies. Hidden dependencies cannot be audited. Compliance cannot be verified.

**Cascade Blindness:** When infrastructure fails, cascading impact is unknown. Responders cannot determine what is affected. Incident response is hampered.

### 6.4 Why It Is Forbidden

Hidden infrastructure dependencies are forbidden because they violate the capability model. RFC-P1-04 requires explicit declaration of dependencies. Dependencies must be declared, not assumed.

Hidden infrastructure dependencies are forbidden because they break orchestration invariants. RFC-P1-02 establishes that all dependencies must be explicit. Hidden dependencies are implicit. Implicit dependencies are prohibited.

Hidden infrastructure dependencies are forbidden because they prevent determinism. RFC-P1-02 requires deterministic deployment outcomes. Hidden dependencies introduce variability based on environmental state not tracked by the orchestrator.

---

## 7. Anti-Pattern: Shadow Infrastructure Provisioning

### 7.1 Description

Shadow infrastructure provisioning is infrastructure created outside platform-sanctioned processes. Infrastructure is provisioned through direct API calls, manual console operations, or unofficial automation.

This pattern manifests as infrastructure created through cloud provider consoles, ad-hoc scripts that provision resources, or tools that bypass platform provisioning workflows.

### 7.2 Why It Occurs

Shadow infrastructure provisioning occurs because:

**Process Friction:** Platform provisioning processes are perceived as slow or bureaucratic. Teams bypass processes to get infrastructure faster.

**Capability Gaps:** Platform processes do not support needed infrastructure types. Teams provision directly because no platform option exists.

**Emergency Response:** Incidents require immediate infrastructure. Teams provision directly because they cannot wait for processes.

**Experimentation:** Teams want to experiment with infrastructure. They provision directly to avoid committing to platform processes.

**Ignorance:** Teams do not know platform processes exist. They provision directly because they do not know there is another way.

### 7.3 Why It Is Harmful

Shadow infrastructure provisioning causes harm because:

**Inventory Incompleteness:** Shadow infrastructure does not appear in platform inventory. The platform does not know it exists. Capacity, cost, and security assessments are incomplete.

**Governance Bypass:** Shadow infrastructure bypasses governance controls. Security reviews, compliance checks, and architectural approval do not occur.

**Cost Invisibility:** Shadow infrastructure costs are not tracked through platform cost management. Costs accumulate without visibility or accountability.

**Operational Orphaning:** Shadow infrastructure has no defined operational owner. When problems occur, there is no one responsible for resolution.

**Lifecycle Disconnection:** Shadow infrastructure is not subject to platform lifecycle management. It is not upgraded, patched, or maintained through platform processes.

**Capability Model Exclusion:** Shadow infrastructure cannot be a capability provider. It exists outside the model. Dependencies on it cannot be declared.

### 7.4 Why It Is Forbidden

Shadow infrastructure provisioning is forbidden because it violates platform ownership. RFC-P2-05 establishes that the platform provisions shared infrastructure. Provisioning outside platform processes bypasses platform ownership.

Shadow infrastructure provisioning is forbidden because it evades eligibility evaluation. RFC-P2-02 requires that infrastructure meeting eligibility criteria be centralized. Shadow infrastructure is never evaluated for eligibility.

Shadow infrastructure provisioning is forbidden because it undermines guarantees. RFC-P2-03 requires the platform to provide guarantees. The platform cannot guarantee infrastructure it does not know exists.

---

## 8. Anti-Pattern: Infrastructure Configuration Overrides by Applications

### 8.1 Description

Infrastructure configuration overrides by applications are modifications to shared infrastructure configuration made by or for specific applications.

This pattern manifests as application-specific configuration injected into shared databases, custom settings applied to shared message queues for individual consumers, or per-application tuning of shared caches.

### 8.2 Why It Occurs

Infrastructure configuration overrides occur because:

**Performance Optimization:** Applications believe they need specific configuration for performance. They request overrides to achieve their performance goals.

**Compatibility Requirements:** Applications require specific configuration to function. Legacy applications may need settings that differ from platform defaults.

**Feature Access:** Applications want to use features not enabled in default configuration. They request overrides to enable those features.

**Isolation Concerns:** Applications believe shared configuration exposes them to other applications' behavior. They request overrides for perceived isolation.

**Historical Entitlement:** Applications had dedicated infrastructure with specific configuration. They expect equivalent configuration in shared infrastructure.

### 8.3 Why It Is Harmful

Infrastructure configuration overrides cause harm because:

**Configuration Fragmentation:** Overrides fragment configuration. Shared infrastructure no longer has uniform configuration. Each override creates a special case.

**Operational Complexity:** Operators must track which overrides apply to which consumers. Troubleshooting requires understanding each consumer's configuration state.

**Upgrade Risk:** Overrides may conflict with upgrades. An upgrade that changes default behavior may break overridden configurations. Upgrade testing must account for all overrides.

**Guarantee Uncertainty:** Platform guarantees assume standard configuration. Overrides may invalidate guarantees. The platform cannot guarantee behavior of non-standard configurations.

**Accountability Blur:** When problems occur, did the platform configuration cause them or did the override? Accountability is unclear.

**Precedent Setting:** Each override sets precedent for more overrides. Override requests multiply. Eventually, every consumer has overrides. Shared configuration no longer exists.

### 8.4 Why It Is Forbidden

Infrastructure configuration overrides are forbidden because they violate platform authority. RFC-P2-05 establishes that the platform configures shared infrastructure. Application-specific overrides transfer configuration authority to applications.

Infrastructure configuration overrides are forbidden because they undermine contract stability. RFC-P2-04 requires stable capability contracts. Overrides create per-consumer contract variations. Contracts are no longer stable.

Infrastructure configuration overrides are forbidden because they fragment operations. RFC-P2-01 established that operational burden distribution is harmful. Overrides distribute configuration management across consumers.

---

## 9. Anti-Pattern Summary

| Anti-Pattern | Primary Harm | Key Violation |
|--------------|--------------|---------------|
| Per-Application Databases | Entropy maximization, operational burden distribution | Ownership rules (RFC-P2-05), eligibility requirements (RFC-P2-02) |
| Embedded Infrastructure in App Charts | Lifecycle coupling, capability hiding | Ownership boundaries (RFC-P2-05), capability model (RFC-P1-04) |
| Application-Owned Operators | Authority confusion, cluster-wide impact | Platform authority (RFC-P2-05), guarantee undermining (RFC-P2-03) |
| Hidden Infrastructure Dependencies | Orchestration failure, non-determinism | Capability model (RFC-P1-04), dependency invariants (RFC-P1-02) |
| Shadow Infrastructure Provisioning | Governance bypass, inventory incompleteness | Platform ownership (RFC-P2-05), eligibility evaluation (RFC-P2-02) |
| Infrastructure Configuration Overrides | Configuration fragmentation, guarantee uncertainty | Platform authority (RFC-P2-05), contract stability (RFC-P2-04) |

---

## 10. Enforcement

### 10.1 Design Review

All design proposals must be reviewed against this anti-pattern list. Designs that incorporate forbidden patterns must be rejected or revised. Review is mandatory before implementation.

### 10.2 Implementation Review

All implementation changes must be reviewed against this anti-pattern list. Implementations that introduce forbidden patterns must be rejected or revised. Review is mandatory before deployment.

### 10.3 Audit

Periodic audits must scan for anti-pattern presence. Discovered anti-patterns must be documented and remediated. Audit findings must be tracked to resolution.

### 10.4 Regression Prevention

This document exists to prevent regression. The patterns listed here represent approaches that have been evaluated and rejected. They are rejected because they cause the harms documented here. Reintroducing them would be regression to a known-harmful state.

When facing a problem, the answer is never a forbidden pattern. Forbidden patterns do not solve problems; they create new problems or mask existing ones. The difficulty of finding a compliant solution does not justify a non-compliant solution.

---

*End of RFC-P2-06*
