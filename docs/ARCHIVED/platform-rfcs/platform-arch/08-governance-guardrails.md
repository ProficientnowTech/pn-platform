```
RFC-PLATARCH-0001                                              Section 8
Category: Standards Track                       Governance & Guardrails
```

# 8. Governance and Guardrails

[← Platform Consumer Model](./07-application-model.md) | [Index](./00-index.md#table-of-contents) | [Next: Rationale →](./09-rationale.md)

---

## 8.1 Overview

This section defines the governance model and guardrails that ensure platform integrity. It covers repository structure, namespace strategy, ArgoCD project governance, resource ownership, resources excluded from GitOps management, and change management processes.

---

## 2. Repository Structure and Git Authority

### 2.1 Git as Source of Truth

Git is the authoritative source of platform state. All platform state MUST be derivable from Git. State that exists only at runtime is drift. Drift is incorrect state that must be corrected.

Git authority means:
- Every change is recorded with history
- Every change has an author
- Every change is reviewable
- Platform state is reconstructable from Git

### 2.2 Repository Organization

Platform configuration is organized into repositories with clear ownership:

**Platform repository:** Platform core, shared infrastructure, platform configuration. Owned by platform team.

**Application repositories:** Application definitions and configurations. Owned by application teams.

Repositories have distinct ownership. Cross-ownership within repositories creates ambiguity.

### 2.3 Directory Structure

Within repositories, directory structure follows consistent patterns:

```
platform-repo/
├── platform/           # Platform core components
├── infrastructure/     # Shared infrastructure
└── config/            # Platform-wide configuration

app-repo/
├── base/              # Application base configuration
└── overlays/          # Environment-specific overlays
```

Structure enables automation. Consistent structure enables consistent tooling.

### 2.4 ArgoCD-Managed Content

ArgoCD manages content that:
- Is defined declaratively in Git
- Has a single source of truth
- Benefits from reconciliation
- Should be restored after cluster recreation

### 2.5 Configuration Principles

**Declarative:** State is declared, not procedurally constructed.

**Versioned:** All configuration is under version control.

**Reviewed:** Changes require review before merge.

**Auditable:** Change history is preserved.

---

## 3. Namespace Strategy and Isolation

### 3.1 Namespace Purpose

Namespaces provide:
- Isolation boundaries between workloads
- Ownership units for responsibility
- Policy enforcement targets
- Blast radius limitation

Namespaces are governance units, not arbitrary groupings.

### 3.2 Dedicated Application Namespaces

Applications MUST have dedicated namespaces when:

- Isolation is required for security or compliance
- Distinct ownership exists
- Independent lifecycle is needed
- Resource governance is required
- Blast radius must be contained

**One application, one namespace** is the standard pattern.

### 3.3 Shared Namespaces

Namespaces MAY be shared when:

- Common ownership exists
- Coordinated governance exists
- Logical cohesion exists
- No isolation requirement exists

Platform infrastructure and shared infrastructure may use shared namespaces.

### 3.4 Namespace Isolation Requirements

Namespaces MUST provide meaningful isolation:

**Network isolation:** Traffic between namespaces denied by default. Explicit allowlisting for required communication. See [RFC-TENANT-SECURITY-0001](../tenant-security/00-index.md) for network policy implementation.

**Access control isolation:** Permissions scoped to namespaces. No cross-namespace grants by default.

**Resource isolation:** Resource quotas and limits per namespace. No resource starvation across namespaces.

### 3.5 Namespace Ownership

Every namespace has exactly one owner:
- Platform namespaces: Platform team
- Application namespaces: Application team

Ownership determines responsibility for resources, compliance, lifecycle, and removal.

### 3.6 Namespace Lifecycle

Namespace lifecycle aligns with content lifecycle:

| Namespace Type | Created | Removed |
|----------------|---------|---------|
| Application | At application deployment | At application removal |
| Platform | At platform initialization | At platform decommissioning |
| Shared infrastructure | At infrastructure provisioning | At infrastructure decommissioning |

Namespaces must not outlive their purpose.

---

## 4. ArgoCD Project Governance

### 4.1 Projects as Permission Boundaries

ArgoCD Projects define:
- Source restrictions (what repositories)
- Destination restrictions (what clusters and namespaces)
- Resource restrictions (what resource types)
- Role restrictions (what operations)

Projects are security enforcement points.

### 4.2 Project Existence Criteria

An AppProject MUST exist for each distinct governance boundary:

**Platform project:** Platform core resources. Elevated permissions for cluster-wide operations. Platform team ownership.

**Shared infrastructure project:** Infrastructure resources. Infrastructure-level permissions. Platform team ownership.

**Application projects:** Application-specific resources. Minimum necessary permissions. Application team ownership with platform oversight.

### 4.3 No Default Project

The ArgoCD default project MUST NOT be used. It has no restrictions. All applications must be in explicitly configured projects.

### 4.4 Blast Radius Containment

Projects MUST contain blast radius:

**Namespace containment:** Application projects deploy only to designated namespaces.

**Cluster containment:** Projects deploy only to designated clusters.

**Resource type containment:** Application projects create only application-level resources.

**Source containment:** Applications source only from designated repositories.

### 4.5 Permission Scoping

Projects MUST have minimum necessary permissions:

**Enumerated namespaces:** List specific permitted namespaces. No wildcards in application projects.

**Allowlisted resources:** List specific permitted resource types. Denied by default.

**Enumerated repositories:** List specific permitted repositories.

**Defined roles:** Users receive roles, not arbitrary permissions.

### 4.6 Resource Whitelisting

Resource restrictions use whitelists, not blacklists:

**Whitelist:** Explicitly permit specific resources; deny all others.

New resources are denied by default. Unknown is untrusted.

Whitelists by project type:
- **Application projects:** Deployments, Services, ConfigMaps, etc.
- **Infrastructure projects:** StatefulSets, PVCs, operator CRDs
- **Platform projects:** CRDs, ClusterRoles, Namespaces

### 4.7 Over-Permission Prohibition

Over-permissive projects are prohibited. Over-permission includes:
- Unnecessary namespace access
- Unnecessary resource access
- Unnecessary repository access
- Unnecessary cluster access

Over-permission creates security, governance, and operational risks.

---

## 5. Resource Ownership and Responsibility

> **Related Reference:** For privileged access management to platform infrastructure (SSH, database access, kubectl access), see [RFC-PAM-0001](../pam/00-index.md).

### 5.1 Ownership Classification

Ownership aligns with binary categorization:

| Classification | Owner | Category | Examples |
|----------------|-------|----------|----------|
| Infrastructure Providers | Platform team | Infrastructure Provider | Operators, CRDs, cert-manager, Crossplane, Keycloak |
| Shared infrastructure operators | Platform team | Infrastructure Provider | Zalando Operator, Strimzi, Rook-Ceph |
| Platform-owned Platform Consumers | Platform team | Platform Consumer | Backstage, Harbor, Grafana, observability stack |
| Tenant applications | Application team | Platform Consumer | Business workloads |

Infrastructure Providers are always platform-owned. Platform Consumers may be platform-owned or application-owned.

### 5.2 Platform-Owned Resources

Platform team responsibilities:
- Provisioning
- Configuration
- Operation
- Maintenance
- Security
- Upgrades
- Decommissioning

Platform team authority:
- Exclusive modification rights
- Exclusive removal rights
- Exclusive configuration rights

### 5.3 Application-Owned Resources

Application team responsibilities:
- Correctness
- Compliance with governance
- Maintenance
- Security within platform constraints
- Removal when decommissioned

Application team authority (within constraints):
- Modification
- Configuration
- Removal (subject to dependency analysis)

### 5.4 CRD Ownership

CRDs are ALWAYS platform-owned:
- Cluster-wide scope
- Schema authority
- API extension
- Stability requirements

Custom Resources (CRs) ownership depends on purpose:
- Platform CRs: Platform-owned
- Application CRs: May be application-owned

### 5.5 Operator Ownership

Operators are Infrastructure Providers and are ALWAYS platform-owned:
- Provide capabilities consumed by base chart templates
- Cannot use base chart (circular dependency)
- Cluster-wide effects
- Elevated privileges
- CRD management
- Stability requirements

Resources created by operators (database instances, Kafka topics, etc.) are provisioned through base chart claims when Platform Consumers declare requirements.

### 5.6 Decommission Responsibility

Decommission aligns with ownership:
- Platform resources: Platform team decommissions
- Shared infrastructure: Follows decommissioning rules
- Application resources: Application owner decommissions

Abandoned resources: Platform assumes responsibility. May be removed after notice.

---

## 6. Resources Not Managed by ArgoCD

### 6.1 Exclusion Principle

Not all resources belong in GitOps. Some resources must not be reconciled by ArgoCD because reconciliation would cause harm.

### 6.2 Classes of Excluded Resources

| Class | Reason | Examples |
|-------|--------|----------|
| Runtime-generated | Created by controllers at runtime | Operator-created resources |
| Ephemeral | Intended to be short-lived | Pods, completed Jobs |
| Status-heavy | Status is primary content | Events, metrics endpoints |
| External system-managed | External system is source of truth | Cloud provider resources |
| Credential material | Secret management is authoritative | Dynamically rotated secrets |
| User data | User data is not in Git | PVCs with application data |

### 6.3 Drift vs. Ownership

**Drift:** Managed resource differs from declared state. ArgoCD corrects drift.

**Ownership:** Determines whether ArgoCD should manage. Unowned resources don't drift in GitOps terms.

Ownership determines management. Drift applies only to managed resources.

### 6.4 Runtime State Separation

Runtime state is separated from declared state:

**Declared state:** Defined in Git, managed by ArgoCD.

**Runtime state:** Created at runtime, not managed by ArgoCD.

Runtime state is protected from reconciliation:
- Not synced
- Not pruned
- Not overwritten

### 6.5 Exclusion Governance

Exclusions must be:
- Documented (what and why)
- Approved (appropriate authority)
- Bounded (minimum scope)
- Auditable (can be verified)

Ungoverned exclusions become shadow infrastructure.

---

## 7. Change Management

### 7.1 When RFCs Are Required

RFCs are required for:
- Architectural changes
- Contract changes
- Governance changes
- Breaking changes
- Cross-cutting changes

Routine changes that do not affect architecture, contracts, or governance do not require RFCs.

### 7.2 RFC Requirements

RFCs must contain:
- Problem statement
- Proposed change
- Impact analysis
- Migration path
- Alternatives considered

Incomplete RFCs must not be approved.

### 7.3 Review Requirements

| Change Type | Review Requirement |
|-------------|-------------------|
| Bug fixes | Standard review |
| Configuration changes | Standard review |
| New applications | Enhanced review |
| Platform component changes | Enhanced review |
| Architectural changes | RFC review |
| Contract changes | RFC review |
| Breaking changes | RFC review |

### 7.4 Breaking Change Governance

Breaking changes are exceptional and require:
- Strong justification
- Exhausted alternatives
- Cost-benefit analysis
- RFC documentation
- Extended review
- Deprecation period
- Migration support
- Communication to affected parties

### 7.5 Deprecation Requirements

Before removal, features must be deprecated:
- Deprecation announcement
- Deprecation period
- Migration guidance
- Removal confirmation (consumers migrated)

Removal without deprecation is prohibited.

### 7.6 API Stability

Capability APIs have stability levels:

| Level | Commitment |
|-------|------------|
| Stable | Breaking changes require major version and deprecation |
| Beta | Breaking changes possible with notice |
| Alpha | Breaking changes may occur without notice |

Stability must be declared. Consumers must know what to expect.

### 7.7 Contract Preservation

Contracts must be preserved long-term:
- Minimum support periods
- Documented deprecation timelines
- Guaranteed migration windows

Contracts are versioned. Version compatibility is documented.

---

## 8. Governance Enforcement

### 8.1 Enforcement Mechanisms

**Automated validation:** Checks prevent non-compliant changes.

**Review gates:** Changes require approval to proceed.

**Audit trails:** Changes tracked for accountability.

**Violation response:** Violations trigger response processes.

### 8.2 Violation Handling

When governance is violated:
1. Detection
2. Assessment
3. Correction
4. Prevention

Violations must not persist uncorrected.

### 8.3 Continuous Improvement

Governance evolves:
- Learn from incidents
- Refine processes
- Incorporate feedback
- Evolve with platform

---

## 9. Summary

### 9.1 Repository Structure

| Principle | Description |
|-----------|-------------|
| Git as source of truth | All state derivable from Git |
| Clear ownership | Repositories have distinct owners |
| Consistent structure | Enables automation |

### 9.2 Namespace Strategy

| Rule | Description |
|------|-------------|
| Dedicated by default | One application, one namespace |
| Meaningful isolation | Network, access control, resource |
| Single ownership | Every namespace has one owner |

### 9.3 ArgoCD Projects

| Rule | Description |
|------|-------------|
| Explicit projects | No default project usage |
| Minimum permissions | Only what is necessary |
| Whitelist resources | Deny by default |
| Contain blast radius | Limit scope of damage |

### 9.4 Ownership

| Component Category | Owner | Base Chart |
|-------------------|-------|------------|
| Infrastructure Providers | Platform team | Prohibited |
| Platform-owned Platform Consumers | Platform team | Required |
| Tenant applications | Application team | Required |
| CRDs and Operators | Platform team (always) | N/A (Infrastructure Providers) |

### 9.5 Excluded Resources

| Class | Rationale |
|-------|-----------|
| Runtime-generated | Not in Git, created dynamically |
| Ephemeral | Meant to be short-lived |
| Status-heavy | Status is runtime-generated |
| External-managed | External system owns |

### 9.6 Change Management

| Change Type | Process |
|-------------|---------|
| Standard | Code review |
| Enhanced | Broader review |
| Architectural | RFC process |
| Breaking | RFC + deprecation + migration |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 7. Platform Consumer Model](./07-application-model.md) | [Table of Contents](./00-index.md#table-of-contents) | [9. Rationale →](./09-rationale.md) |

---

*End of Section 8 — RFC-PLATARCH-0001*
