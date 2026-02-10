```
RFC-IAM-0001                                                  Section 1
Category: Standards Track                              Introduction
```

# 1. Introduction

[← Index](./00-index.md) | [Index](./00-index.md#table-of-contents) | [Next: Requirements →](./02-requirements.md)

---

## 1.1 Background and Context

### 1.1.1 Scope of This RFC

This RFC addresses **web UI authentication** and **application-level authorization** for platform developer tools. When a developer opens a platform application (container registry, package registry, developer portal) in their browser and clicks "Login," this RFC governs what happens. When that developer attempts to create a project or access a resource, this RFC governs whether they are permitted to do so.

This RFC does **not** address:
- How Kubernetes pods authenticate to each other (workload identity)
- How developers SSH into servers (privileged access)
- How CI/CD pipelines authenticate to deploy (machine identity)
- How services authenticate to databases (service-to-service)

These concerns are important but represent fundamentally different architectural challenges addressed by separate specifications.

### 1.1.2 The Federation Challenge

Modern platform engineering organizations operate within enterprise environments where identity management spans multiple systems with distinct responsibilities. Azure Active Directory serves as the enterprise identity provider, managing user accounts, group memberships, and organizational policies. Internal development platforms require their own identity-aware services to provide fine-grained access control for developer tools with web interfaces.

The challenge lies not in choosing between enterprise and platform identity systems, but in establishing a coherent architecture that leverages both while maintaining consistent security guarantees. Enterprise identity systems excel at organizational identity management but lack the specialized protocols and integration capabilities required by cloud-native developer tooling. Conversely, platform identity providers like Keycloak offer rich OIDC integration features but cannot replace enterprise identity governance.

This RFC addresses the architectural challenge of federating these identity systems for **web application authentication** in a manner that preserves enterprise security boundaries while enabling rich platform functionality.

## 1.2 Current State Analysis

### 1.2.1 Identity Fragmentation

Platform tools currently authenticate users through disparate mechanisms. Some applications integrate directly with Azure AD, others maintain local user databases, and still others rely on static credentials stored in configuration files. This fragmentation creates several operational challenges:

- **Inconsistent user experience**: Users maintain multiple credentials and encounter different authentication flows across tools
- **Audit complexity**: Security teams cannot construct a unified view of user access across the platform
- **Provisioning overhead**: User onboarding and offboarding requires manual intervention across multiple systems
- **Policy enforcement gaps**: Access policies defined in Azure AD do not propagate to all platform tools

### 1.2.2 Authorization Silos

Authorization decisions are made independently by each application based on local configurations. When Azure AD group memberships change, these changes do not automatically reflect in application-level permissions. The result is authorization drift where users retain access to resources after their organizational permissions have been revoked, or conversely, are denied access to resources they should be able to reach.

### 1.2.3 Secret Sprawl

Secrets required for application authentication and inter-service communication are distributed across multiple storage mechanisms:

- Kubernetes Secrets in individual namespaces
- Environment variables in deployment configurations
- Configuration files mounted as volumes
- Hardcoded values in application code

This distribution complicates secret rotation, increases the attack surface, and prevents centralized auditing of secret access.

### 1.2.4 Manual Configuration Burden

Adding new applications to the platform requires manual configuration of:

- Authentication providers within each application
- User and group mappings
- Secret distribution
- Access control policies

This manual burden slows platform expansion and introduces configuration errors that manifest as security vulnerabilities or access failures.

## 1.3 Operational Challenges

### 1.3.1 The Permission Bypass Problem

The most critical operational challenge is the potential for downstream systems to grant access that exceeds enterprise permissions. Consider a scenario where:

1. A user belongs to Azure AD group "Development" but not "Production"
2. Azure AD policies restrict the user from production resources
3. A platform administrator configures Keycloak to grant the user a "production-access" role
4. The user accesses production resources through a Keycloak-integrated application

In this scenario, the platform identity system has bypassed enterprise security policy. This represents a fundamental security violation that current architectures do not prevent.

### 1.3.2 Synchronization Latency

When organizational changes occur in Azure AD—user termination, group membership changes, or policy updates—these changes must propagate to all platform systems. Current architectures lack defined synchronization mechanisms, resulting in:

- Terminated users retaining access for extended periods
- Group membership changes not reflecting in application permissions
- No clear audit trail of when changes propagated

### 1.3.3 GitOps Boundary Ambiguity

Platform teams embrace GitOps for infrastructure and application deployment, but identity configuration presents unique challenges:

- User and group assignments require human judgment that cannot be automated
- Role definitions and permission mappings are suitable for GitOps
- The boundary between declarative configuration and administrative action is unclear

Without clear boundaries, teams either over-automate identity management (creating security risks) or under-automate it (creating operational burden).

### 1.3.4 Developer Self-Service Limitations

Developers require self-service capabilities to create projects, repositories, and other resources within platform tools. Current architectures force a choice between:

- **Full self-service**: Developers can create any resource, bypassing organizational controls
- **Ticket-based requests**: All resource creation requires administrative intervention

Neither extreme serves the organization well. The architecture must enable controlled self-service where developers can take actions permitted by their organizational role without administrative overhead.

## 1.4 Motivation for This Architecture

### 1.4.1 Unified Identity with Preserved Boundaries

This architecture establishes Keycloak as the unified identity provider for all platform applications while preserving Azure AD as the authoritative source of organizational identity and permissions. The key insight is that federation does not require equality—Azure AD permissions form an immutable ceiling that Keycloak cannot exceed.

### 1.4.2 Declarative Security Configuration

By integrating identity configuration with the GitOps deployment model through Crossplane providers and Helm templating, the architecture enables:

- Version-controlled security configurations
- Peer review of permission changes
- Automated deployment of identity-dependent resources
- Consistent configuration across environments

### 1.4.3 Centralized Secrets with Distributed Access

Vault serves as the single source of truth for secrets, with External Secrets Operator providing controlled distribution to application namespaces. This model ensures:

- Centralized secret lifecycle management
- Auditable access to all secrets
- Automated rotation without application changes
- Namespace-scoped access controls

### 1.4.4 Controlled Developer Self-Service

The developer portal (Backstage) enables users to create and manage platform resources through self-service workflows. The complete developer portal architecture is defined in RFC-DEVELOPER-PLATFORM (planned). This RFC establishes only the identity integration: all portal authentication flows through Keycloak, and Keycloak tokens provide the permission claims that govern what users can do.

### 1.4.5 Extensible Integration Model

The architecture defines clear integration patterns that any platform application can adopt. The patterns described in this RFC apply to container registries, package registries, developer portals, and any future platform tools with web interfaces. This extensibility ensures the architecture remains relevant as the platform evolves.

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← Index](./00-index.md) | [Table of Contents](./00-index.md#table-of-contents) | [2. Requirements →](./02-requirements.md) |

---

*End of Section 1*
