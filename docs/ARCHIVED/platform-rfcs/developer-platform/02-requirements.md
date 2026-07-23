```
RFC-DEVELOPER-PLATFORM-0001                                       Section 2
Category: Standards Track                                     Requirements
```

# 2. Requirements

[← Introduction](./01-introduction.md) | [Index](./00-index.md#table-of-contents) | [Next: Architecture →](./03-architecture.md)

---

## 2.1 Problem Restatement

### 2.1.1 Scope Definition

This RFC addresses **developer interaction with the platform** through a unified portal. Specifically:

| In Scope | Description |
|----------|-------------|
| Developer portal framework | Backstage as the unified interface |
| Service discovery | Finding and understanding platform services |
| Self-service workflows | Project creation, infrastructure provisioning, access requests |
| Documentation integration | TechDocs for documentation-as-code |
| Tool navigation | Permission-aware links to platform tools |

| Out of Scope | Addressed By |
|--------------|--------------|
| Authentication flows | RFC-IAM-0001 |
| Secrets management | RFC-SECOPS-0001 |
| Privileged access implementation | RFC-PAM-0001 |
| WAF and network policies | RFC-TENANT-SECURITY |
| Service mesh | RFC-WORKLOAD-IDENTITY |

### 2.1.2 Core Requirements

The platform requires a developer portal that:

1. Provides a unified entry point for all developer interactions with the platform
2. Enables service discovery through a centralized catalog
3. Supports self-service workflows within organizational guardrails
4. Integrates documentation with the services it describes
5. Presents a capability-based UI where users see only permitted actions
6. Integrates with GitOps for all infrastructure changes

---

## 2.2 Design Goals

### 2.2.1 Unified Developer Experience

Developers SHOULD interact with platform capabilities through a single interface. The portal SHOULD consolidate:

| Capability | Current State | Target State |
|------------|---------------|--------------|
| Service discovery | Ask colleagues | Search catalog |
| Project creation | Manual setup | Template scaffolding |
| Infrastructure provisioning | File tickets | Self-service templates |
| Documentation | Scattered wikis | TechDocs integration |
| Tool access | Bookmarked URLs | Permission-aware tool library |

### 2.2.2 Capability-Based Authorization

The portal SHOULD present users only with actions they are permitted to perform. This approach:

| Principle | Implementation |
|-----------|----------------|
| No runtime blocking | Authorization at visibility level, not action level |
| Keycloak-driven | Permission claims from Keycloak tokens |
| Consistent | Same permission model across all portal features |
| Transparent | Users understand their capabilities |

### 2.2.3 GitOps-First Operations

All self-service actions that modify infrastructure SHOULD produce Git commits. This ensures:

| Benefit | Description |
|---------|-------------|
| Audit trail | All changes tracked in version control |
| Peer review | Optional review for sensitive changes |
| Rollback capability | Revert changes through Git |
| Declarative state | Git represents desired state |

### 2.2.4 Golden Path Templates

Software templates SHOULD encode organizational standards. Templates:

| Characteristic | Description |
|----------------|-------------|
| Opinionated | Embody best practices |
| Consistent | Produce uniform project structures |
| Validated | Include required elements (security, monitoring) |
| Maintained | Updated as standards evolve |

### 2.2.5 Documentation Proximity

Documentation SHOULD live alongside the code it describes. The portal:

| Capability | Description |
|------------|-------------|
| Renders docs from code | MkDocs in repository rendered in portal |
| Links docs to services | Documentation visible on service pages |
| Enables search | Cross-service documentation search |
| Tracks freshness | Visibility into documentation currency |

---

## 2.3 Non-Goals

### 2.3.1 Replacing Specialized Tools

The portal does not replace specialized tools for complex operations. Users MAY navigate to full-featured tools for:

| Tool | Portal Role | Full Tool For |
|------|-------------|---------------|
| Grafana | Dashboard links, status | Complex queries, alert configuration |
| ArgoCD | Sync status, quick actions | Multi-app deployments, history |
| Kafka UI | Topic overview | Consumer lag analysis, message inspection |
| Harbor | Vulnerability summary | Replication rules, garbage collection |

### 2.3.2 Implementing Authentication

Authentication is the domain of RFC-IAM-0001. This RFC consumes:

| From RFC-IAM-0001 | This RFC Uses |
|-------------------|---------------|
| Keycloak OIDC client | Portal authentication |
| Token claims | Permission decisions |
| Group memberships | Access control |

### 2.3.3 Implementing Secrets Management

Secrets management is the domain of RFC-SECOPS-0001. This RFC consumes:

| From RFC-SECOPS-0001 | This RFC Uses |
|----------------------|---------------|
| Vault secrets | Portal configuration, plugin credentials |
| ESO distribution | Secrets delivered to portal namespace |

### 2.3.4 Implementing Privileged Access

Privileged access is the domain of RFC-PAM-0001. This RFC:

| Provides | RFC-PAM-0001 Implements |
|----------|-------------------------|
| Access request UI | Teleport API integration |
| Session links | Session recording and playback |
| Credential display | Short-lived credential issuance |

### 2.3.5 Implementing Application Security

Application security is the domain of RFC-TENANT-SECURITY. This RFC:

| Depends On | RFC-TENANT-SECURITY Provides |
|------------|------------------------------|
| WAF protection | BunkerWeb protects portal |
| Network isolation | Portal namespace policies |

---

## 2.4 Architectural Invariants

The following invariants MUST hold true at all times. Violation of any invariant represents an architectural failure requiring remediation.

### Invariant 1 — Authentication Chain

All developer portal authentication MUST flow through Keycloak.

The portal MUST NOT implement independent authentication mechanisms. Authentication decisions MUST be delegated to Keycloak as specified in RFC-IAM-0001 Invariant 2.

This invariant ensures consistent identity validation and enables the authorization ceiling model.

### Invariant 2 — Capability-Based UI Rendering

Portal authorization MUST use capability-based UI rendering.

Users MUST see only actions they are permitted to perform. The portal MUST NOT present options that would result in permission-denied errors. Authorization is enforced through visibility, not through blocking attempted actions.

This invariant simplifies user experience and reduces error scenarios.

### Invariant 3 — Permission Source

Backstage permission decisions MUST derive from Keycloak token claims.

The portal MUST NOT maintain independent permission databases. All authorization decisions MUST trace to claims present in the user's Keycloak token (groups, roles, custom claims).

This invariant ensures single source of truth for permissions and supports the RFC-IAM-0001 authorization ceiling model.

### Invariant 4 — GitOps Output

All self-service actions that modify infrastructure MUST produce Git commits.

No infrastructure change MAY be applied directly through APIs or CLI tools. Templates and workflows MUST output Git commits that are subsequently reconciled by GitOps controllers (ArgoCD, Crossplane).

This invariant ensures audit trails, enables peer review, and supports rollback.

### Invariant 5 — Golden Path Enforcement

Software Templates MUST follow organizational golden paths.

Templates MUST NOT allow arbitrary project structures. Each template MUST produce output conforming to organizational standards for:

| Standard | Enforcement |
|----------|-------------|
| Project structure | Template-defined directories and files |
| CI/CD configuration | Required pipeline definitions |
| Security controls | Required security scanning, secrets management |
| Monitoring | Required observability configuration |

This invariant ensures consistency and reduces configuration drift.

### Invariant 6 — Platform Guardrails

Self-service workflows MUST operate within platform guardrails.

Workflows MUST enforce:

| Guardrail | Description |
|-----------|-------------|
| Resource quotas | Maximum resources per environment tier |
| Naming conventions | Required naming patterns |
| Approval workflows | Sensitive operations require approval |
| Environment restrictions | Production access requires additional authorization |

This invariant prevents resource exhaustion and enforces organizational policies.

### Invariant 7 — Catalog Ownership

Catalog entities MUST have defined ownership.

Every entity in the Software Catalog MUST specify an owner (team or individual). Entities MUST NOT exist without ownership assignment.

This invariant ensures accountability and enables permission-based visibility.

### Invariant 8 — Documentation Colocation

Documentation MUST be co-located with code.

TechDocs documentation MUST reside in the same repository as the code it describes. Documentation MUST NOT be maintained in separate systems (external wikis, shared drives).

This invariant ensures documentation currency and reduces drift.

### Invariant 9 — Short-Lived Credentials

Database credentials obtained through the portal MUST be short-lived.

Credentials MUST be issued through Vault dynamic secrets engine or Teleport certificate issuance (per RFC-PAM-0001). Static, long-lived database credentials MUST NOT be exposed through the portal.

This invariant minimizes credential exposure window and supports audit requirements.

### Invariant 10 — Tool Authorization Boundaries

Tool links MUST respect user authorization boundaries.

The tool library MUST filter displayed tools based on user permissions. Users MUST NOT see links to tools or resources they cannot access. Deep links MUST be scoped to authorized namespaces, projects, or resources.

This invariant prevents confusion and maintains the capability-based model.

### Invariant 11 — Production Restore Approval

Production database restore operations MUST require approval workflow.

Restore operations for production databases MUST NOT be self-service. Restore requests MUST flow through an approval workflow with at least one approver other than the requester.

This invariant protects production data integrity.

### Invariant 12 — Schema Compatibility Validation

Schema changes MUST pass compatibility validation.

Schema registration in Apicurio Registry MUST validate compatibility with existing schemas. Incompatible schema changes MUST be rejected unless explicitly overridden with approval.

This invariant prevents breaking changes in event-driven systems.

### Invariant 13 — Session Recording

All privileged access MUST be session-recorded.

Access to databases, servers, or pods obtained through the portal MUST be recorded per RFC-PAM-0001. The portal MUST integrate with Teleport for access that requires session recording.

This invariant ensures audit compliance.

### Invariant 14 — Plugin Permission Integration

Plugin extensions MUST integrate with the permission framework.

Custom plugins MUST NOT bypass Backstage's permission framework. Plugins MUST declare required permissions and respect permission policy decisions.

This invariant ensures consistent authorization across all portal features.

### Invariant 15 — Authentication Chain Integrity

Plugins MUST NOT bypass the Keycloak authentication chain.

Plugins that communicate with external systems MUST NOT implement independent authentication that circumvents Keycloak. External system access MUST use:

| Pattern | Description |
|---------|-------------|
| Service account | Plugin uses dedicated service account |
| User token forwarding | User's Keycloak token forwarded to external system |
| Vault-issued credentials | Credentials obtained from Vault |

This invariant maintains the security boundary defined in RFC-IAM-0001.

---

## 2.5 Success Criteria

### 2.5.1 Developer Experience Criteria

| Criterion | Validation |
|-----------|------------|
| Single entry point | Developers access platform through one URL |
| Service discoverability | Developers can find services through catalog search |
| Self-service functional | Common operations complete without platform team involvement |
| Documentation accessible | Docs visible alongside services in catalog |

### 2.5.2 Security Criteria

| Criterion | Validation |
|-----------|------------|
| Authentication through Keycloak | No independent auth mechanisms |
| Capability-based UI | Users see only permitted actions |
| Audit trails | All self-service actions logged |
| Session recording | Privileged access recorded |

### 2.5.3 Operational Criteria

| Criterion | Validation |
|-----------|------------|
| GitOps output | All infrastructure changes via Git |
| Template consistency | Projects follow organizational standards |
| Plugin extensibility | New integrations addable via plugins |

### 2.5.4 Integration Criteria

| Criterion | Validation |
|-----------|------------|
| RFC-IAM-0001 | Portal authenticates through Keycloak |
| RFC-SECOPS-0001 | Secrets delivered via ESO |
| RFC-PAM-0001 | JIT access requests functional |
| RFC-TENANT-SECURITY | Portal protected by WAF |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 1. Introduction](./01-introduction.md) | [Table of Contents](./00-index.md#table-of-contents) | [3. Architecture →](./03-architecture.md) |

---

*End of Section 2 — RFC-DEVELOPER-PLATFORM-0001*
