```
RFC-PLATARCH-0001                                              Section 7
Category: Standards Track                            Application Model
```

# 7. Application Model

[← Shared Infrastructure](./06-shared-infrastructure.md) | [Index](./00-index.md#table-of-contents) | [Next: Governance →](./08-governance-guardrails.md)

---

## 7.1 Overview

This section defines the application model for platform applications. It covers capability declarations, secret and identity integration, networking and exposure rules, and application removal semantics. These rules ensure applications integrate consistently with the platform.

---

## 2. Capability Declaration Requirements

### 2.1 Declaration Mandate

Applications MUST declare all capabilities they require and all capabilities they provide. Undeclared capabilities do not exist from the orchestrator's perspective.

Declaration is explicit. There is no capability inference. If an application needs a database, it declares the database capability requirement. If an application provides an API, it declares the API capability provision.

### 2.2 Required Capability Declaration

For each required capability, applications MUST declare:

**Capability name:** The unique identifier for the capability being required.

**Version constraint:** The minimum acceptable contract version.

**Requirement type:** Whether the requirement is mandatory or optional.

Mandatory requirements block deployment until satisfied. Optional requirements do not block deployment but affect application behavior if unsatisfied.

### 2.3 Provided Capability Declaration

For each provided capability, applications MUST declare:

**Capability name:** The unique identifier for the capability being provided.

**Contract version:** The version of the capability contract being satisfied.

**Readiness conditions:** How the orchestrator determines when the capability is ready.

Provided capabilities are registered with the orchestrator upon successful deployment.

### 2.4 Declaration Location

Capability declarations are specified in the application's values file for the base chart:

```yaml
capabilities:
  required:
    - name: postgresql-database
      version: ">=2.0.0"
      required: true
    - name: redis-cache
      version: ">=1.0.0"
      required: false
  provided:
    - name: user-api
      version: "1.2.0"
      readiness:
        endpoint: /health
        port: 8080
```

### 2.5 Declaration Validation

Declarations are validated at multiple stages:

**Commit time:** CI validates declaration syntax and referenced capabilities exist.

**Deployment time:** Orchestrator validates requirements can be satisfied.

**Runtime:** Readiness probes verify provided capabilities.

Invalid declarations prevent deployment.

### 2.6 Declaration Updates

When declaration requirements change:

**Adding requirement:** Application waits for new requirement satisfaction.

**Removing requirement:** No blocking effect. Application no longer waits for the capability.

**Adding provision:** New capability becomes available after deployment.

**Removing provision:** Consumers of the capability must migrate first.

---

## 3. Secrets, Configuration, and Identity

> **Normative Reference:** This section establishes requirements for secrets and identity. Implementation details are specified in [RFC-SECOPS-0001](../secret-ops/00-index.md) (secrets management) and [RFC-WORKLOAD-IDENTITY-0001](../workload-identity/01-introduction.md) (workload identity).

### 3.1 Secret Declaration

Applications MUST declare all secrets they require. Applications MUST NOT create secrets. The platform provisions secrets according to declarations.

Secret declaration specifies:
- Secret name (application-local identifier)
- Secret type (credential, certificate, key, etc.)
- Provider reference (which platform secret capability)

### 3.2 Secret Provisioning

The platform provisions secrets:

1. Application declares secret requirement
2. Platform secret infrastructure creates secret material
3. Secret is stored in platform secret management
4. Secret is delivered to application through injection mechanism
5. Secret is rotated according to platform policy

Applications receive secrets. They do not create them.

### 3.3 Platform Identity

Every platform application has platform-assigned identity. Identity is used for:

- Authentication to platform services
- Authorization for capability access
- Audit trail attribution

Applications MUST NOT create or manage their own identity credentials.

> **Implementation Reference:** Workload identity is implemented using SPIFFE/SPIRE attestation-based identity as specified in [RFC-WORKLOAD-IDENTITY-0001](../workload-identity/01-introduction.md). Human web authentication is handled by Keycloak SSO as specified in [RFC-IAM-0001](../iam/00-index.md).

### 3.4 Identity Scope

Application identity is scoped:

- Identity grants access to the application's own resources
- Identity grants access to declared capability consumption
- Identity does not grant access to other applications' resources

Identity scope is enforced by the platform.

### 3.5 Secret Prohibitions

The following are prohibited:

| Pattern | Problem |
|---------|---------|
| Inline secrets | Not rotatable, exposed in repos |
| Unmanaged environment variables | Bypass management, not auditable |
| Self-generated credentials | Unmanaged, may be weak |
| Hardcoded connection strings | Embed secrets, not rotatable |
| Credential logging | Exposed in logs |
| External secret stores | Bypass platform governance |

Violations of these prohibitions fail validation.

### 3.6 Configuration vs. Secrets

Configuration and secrets are distinct:

**Configuration:** Non-sensitive settings. May be in ConfigMaps, values files.

**Secrets:** Sensitive material. MUST be in platform secret infrastructure.

Misclassifying secrets as configuration is a violation.

---

## 4. Networking, Ingress, and Exposure

> **Normative Reference:** This section establishes networking requirements. Implementation details including WAF configuration, network policies, and ingress protection are specified in [RFC-TENANT-SECURITY-0001](../tenant-security/00-index.md).

### 4.1 Exposure Decision

Not all applications require external exposure. The default is internal-only. External exposure requires explicit declaration and justification.

Exposure types:
- **Internal:** Accessible only within the platform
- **External:** Accessible from outside the platform

### 4.2 When External Exposure Is Permitted

External exposure is permitted when:

- Application serves external users
- Application integrates with external systems
- Application provides platform-wide services requiring external access

External exposure is NOT default. Internal exposure limits attack surface.

### 4.3 TLS Requirements

All exposed services MUST use TLS. There are no exceptions.

**External services:** Platform-provided certificates from recognized authorities.

**Internal services:** Platform internal CA or service mesh encryption.

Applications MUST NOT manage their own certificates.

### 4.4 Exposure Classification

Every exposed service MUST be classified:

| Classification | Access | Controls |
|----------------|--------|----------|
| Internal | Platform-internal only | Network policies, internal auth |
| External | From outside platform | WAF, public certs, enhanced monitoring |

Classification determines security controls.

### 4.5 Naming Conventions

Exposed services MUST follow platform naming conventions:

- Service names follow platform patterns
- Hostnames are derived from platform rules
- Names are validated against conventions
- Name changes are breaking changes

### 4.6 Security Posture

Exposed services MUST implement:

**Authentication:** All services require authentication by default. Anonymous access requires explicit justification.

**Authorization:** Role-based or policy-based access control. Default deny.

**Rate limiting:** Protection against abuse.

**Input validation:** All input must be validated.

**Security monitoring:** Authentication/authorization failures logged.

### 4.7 Exposure Prohibitions

The following are prohibited:

| Pattern | Problem |
|---------|---------|
| Unencrypted exposure | No protection for data in transit |
| Self-managed certificates | Inconsistent, may expire |
| Arbitrary port exposure | Non-standard, harder to secure |
| Network bypass | Circumvents security controls |
| Anonymous external access (default) | Requires explicit justification |
| Overly broad exposure | Unnecessary attack surface |

---

## 5. Application Removal and Decommissioning

### 5.1 Removal Trigger

Application removal is triggered by deleting the application definition from Git. Git is the source of truth. When an application is absent from Git, it is removed from the platform.

### 5.2 Pre-Removal Validation

Before removal proceeds, the platform validates:

**Dependency check:** No other applications depend on capabilities this application provides.

**Consumer notification:** If consumers exist, removal does not proceed automatically.

**Data handling:** Data disposition requirements are addressed.

Removal that would break other applications does not proceed automatically.

### 5.3 Removal Execution

When pre-removal validation passes:

1. Kubernetes resources are deleted
2. Capabilities are de-registered from orchestrator
3. Identity credentials are revoked
4. Secrets are cleaned up according to policy

### 5.4 Shared Infrastructure Treatment

Shared infrastructure is NOT affected by application removal. When an application that consumes shared infrastructure is removed:

- Infrastructure remains
- Application's data in infrastructure follows data ownership rules
- No cascade to infrastructure

Infrastructure removal follows platform decommissioning rules, not application removal.

### 5.5 Data Ownership Rules

Application data belongs to the application owner. Data disposition must be declared before removal:

| Option | Description |
|--------|-------------|
| Retained | Data preserved after removal |
| Migrated | Data moved to another system |
| Archived | Data moved to archive storage |
| Deleted | Data permanently deleted |

Disposition must be explicit. No default disposition.

### 5.6 Orphan Prevention

Removal MUST NOT orphan dependencies. If consumers depend on capabilities being removed:

1. Consumers are identified
2. Consumers are notified
3. Blocking dependencies prevent automatic removal
4. Non-blocking dependencies proceed with notification

Forced removal is exceptional and requires justification.

### 5.7 Lifecycle Finalization

Complete removal means:

- No remaining resources
- No remaining artifacts
- No orphaned dependencies
- Data disposed according to declarations
- Removal recorded for audit

Incomplete removal leaves debris. Finalization is verified.

### 5.8 Removal Irreversibility

Removal is not reversible through platform mechanisms:

- Resources are deleted
- Data may be deleted
- Identity is revoked

Redeployment is new deployment, not recovery. Removed applications restart from clean state.

---

## 6. Base Chart Integration

### 6.1 Integration Mechanism

The base chart is the single integration mechanism. Applications include the base chart as a dependency and configure it through values.

```yaml
# Chart.yaml
dependencies:
  - name: platform-base
    version: "3.2.0"
    repository: "https://charts.platform.internal"
```

### 6.2 Required Configuration

Applications MUST configure:

- Capability declarations (required and provided)
- Secret requirements
- Resource requests and limits
- Exposure configuration (if needed)

### 6.3 Base Chart Responsibilities

The base chart handles:

- Capability declaration registration
- Secret injection wiring
- Network policy generation
- Resource constraint enforcement
- Monitoring integration
- Identity wiring

Applications do not implement these integrations directly.

### 6.4 Version Pinning

Applications specify the base chart version they use. Version upgrades are explicit changes that go through review.

Breaking changes in the base chart require:
1. Deprecation notice
2. Migration period
3. Application team update
4. Version bump in application

---

## 7. Prohibited Application Patterns

### 7.1 Direct Infrastructure Access

Applications MUST NOT access infrastructure directly. All access MUST be through capability interfaces.

### 7.2 CRD Creation

Applications MUST NOT create CRDs. CRDs are platform resources.

### 7.3 Operator Installation

Applications MUST NOT install operators. Operators are platform-owned.

### 7.4 Cluster-Wide Resources

Applications MUST NOT create cluster-wide resources (ClusterRoles, ClusterRoleBindings, etc.) without platform approval.

### 7.5 Cross-Namespace Access

Applications MUST NOT access resources in other namespaces without explicit authorization through capabilities.

### 7.6 Base Chart Bypass

Applications MUST NOT deploy without the base chart. All platform applications use the base chart.

---

## 8. Summary

### 8.1 Capability Declarations

| Declaration Type | Required Content |
|------------------|------------------|
| Required capability | Name, version, mandatory/optional |
| Provided capability | Name, version, readiness conditions |

### 8.2 Secret and Identity

| Element | Rule |
|---------|------|
| Secrets | Declared, not created |
| Identity | Platform-assigned |
| Configuration | Separate from secrets |

### 8.3 Networking

| Aspect | Default | Override |
|--------|---------|----------|
| Exposure | Internal | Explicit declaration |
| TLS | Required | No override |
| Authentication | Required | Justification for anonymous |

### 8.4 Removal

| Phase | Action |
|-------|--------|
| Validation | Check dependencies, data disposition |
| Execution | Delete resources, de-register capabilities |
| Verification | Confirm clean state |

### 8.5 Prohibitions

- No direct infrastructure access
- No CRD creation
- No operator installation
- No cluster-wide resources
- No cross-namespace access
- No base chart bypass

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 6. Shared Infrastructure](./06-shared-infrastructure.md) | [Table of Contents](./00-index.md#table-of-contents) | [8. Governance →](./08-governance-guardrails.md) |

---

*End of Section 7 — RFC-PLATARCH-0001*
