```
RFC-PAM-0001                                                      Index
Category: Standards Track                     Privileged Access Management
```

# RFC-PAM-0001: Privileged Access Management Architecture

[Index](#table-of-contents)

---

## RFC Metadata

| Field | Value |
|-------|-------|
| RFC ID | RFC-PAM-0001 |
| Title | Privileged Access Management Architecture |
| Kind | Architecture |
| Status | Draft |
| Category | Standards Track |
| Author | Platform Engineering |
| Created | 2026-02-10 |
| Last Updated | 2026-02-10 |
| Version | 1.0.0 |

---

## Abstract

This RFC defines the architecture for **privileged access management** (PAM) governing human access to infrastructure resources including SSH servers, databases, and Kubernetes clusters. It positions Teleport as the centralized access broker, integrating with Keycloak for identity (per RFC-IAM-0001) and Vault for credential management (per RFC-SECOPS-0001).

The architecture enforces a **zero direct access** model where all privileged sessions flow through Teleport with mandatory session recording, certificate-based authentication, and just-in-time access workflows. This eliminates standing credentials, provides comprehensive audit trails, and enables fine-grained access control based on the authorization ceiling established by Azure AD group memberships.

### Scope Boundaries

| In Scope | Out of Scope |
|----------|--------------|
| SSH access to Linux/Unix servers | Web UI SSO (RFC-IAM-0001) |
| Database client sessions (psql, mysql, mongosh) | Service-to-service authentication (RFC-WORKLOAD-IDENTITY) |
| Kubernetes exec/attach/port-forward | Secret storage and rotation mechanics (RFC-SECOPS-0001) |
| Windows RDP access | Network-level security policies (RFC-TENANT-SECURITY) |
| Session recording and playback | Self-service UI workflows (RFC-DEVELOPER-PLATFORM) |
| Just-in-time access requests | CI/CD pipeline credentials |
| Command and query auditing | API token management for services |

This RFC addresses **interactive human users accessing infrastructure**—not automated workloads, web applications, or machine identity.

### Primary Question

> "Can this human access this infrastructure resource?"

### Relationship to Other RFCs

This RFC is part of a family of platform architecture specifications:

| RFC | Domain | Relationship to RFC-PAM-0001 |
|-----|--------|------------------------------|
| **[RFC-IAM-0001](../iam/00-index.md)** | Web UI Auth | Provides identity layer (Keycloak SSO) |
| **[RFC-SECOPS-0001](../secret-ops/00-index.md)** | Secrets Management | Provides credential authority (Vault SSH/DB engines) |
| **[RFC-WORKLOAD-IDENTITY-0001](../workload-identity/00-index.md)** | Workload Identity | Parallel RFC for machine-to-machine access |
| **[RFC-DEVELOPER-PLATFORM-0001](../developer-platform/00-index.md)** | Developer Portal | Provides self-service access request UI |
| **[RFC-TENANT-SECURITY-0001](../tenant-security/00-index.md)** | Application Security | Complementary network-level controls |

**Normative Dependencies**:
- RFC-IAM-0001 is **normative** for identity concerns—RFC-PAM-0001 MUST authenticate users through Keycloak
- RFC-SECOPS-0001 is **normative** for credential concerns—RFC-PAM-0001 MUST use Vault for SSH certificates and database credentials

---

## Table of Contents

### Core Sections

1. [Introduction](./01-introduction.md)
   - 1.1 Background and Context
   - 1.2 Current State Analysis
   - 1.3 The Problem with Traditional Access
   - 1.4 Motivation for This Architecture

2. [Requirements](./02-requirements.md)
   - 2.1 Problem Restatement
   - 2.2 Design Goals
   - 2.3 Non-Goals
   - 2.4 Architectural Invariants
   - 2.5 Success Criteria

3. [Architecture](./03-architecture.md)
   - 3.1 System Overview
   - 3.2 Zero Direct Access Model
   - 3.3 Trust Hierarchy
   - 3.4 Authority Domains
   - 3.5 Trust Boundaries
   - 3.6 Data Flow Model

4. [Components](./04-components.md)
   - 4.1 Teleport Cluster
   - 4.2 Teleport Agents
   - 4.3 Vault SSH Secrets Engine
   - 4.4 Vault Database Secrets Engine
   - 4.5 External Secrets Operator
   - 4.6 Target Resources

### Domain-Specific Sections

5. [Identity Integration](./05-identity-integration.md)
   - 5.1 Keycloak SSO Configuration
   - 5.2 Group-to-Role Mapping
   - 5.3 Authorization Ceiling Enforcement
   - 5.4 Token Claims for Access Decisions

6. [SSH Access](./06-ssh-access.md)
   - 6.1 Certificate-Based Authentication
   - 6.2 Vault SSH CA Integration
   - 6.3 Host Enrollment
   - 6.4 User Certificate Flow
   - 6.5 Principal Mapping

7. [Database Access](./07-database-access.md)
   - 7.1 Dynamic Credential Model
   - 7.2 Vault Database Engine Integration
   - 7.3 Supported Database Protocols
   - 7.4 Credential Lifecycle
   - 7.5 Query Logging

8. [Kubernetes Governance](./08-kubernetes-governance.md)
   - 8.1 exec/attach Access Control
   - 8.2 Port-Forward Governance
   - 8.3 Namespace-Based Policies
   - 8.4 Integration with Kubernetes RBAC
   - 8.5 eBPF Session Capture

9. [Session Management](./09-session-management.md)
   - 9.1 Session Recording Requirements
   - 9.2 Recording Storage
   - 9.3 Session Playback
   - 9.4 Live Session Moderation
   - 9.5 Audit Log Integration

10. [Access Requests](./10-access-requests.md)
    - 10.1 Just-in-Time Access Model
    - 10.2 Request Workflow
    - 10.3 Approval Chains
    - 10.4 Time-Bound Access Grants
    - 10.5 Notification Integration

11. [GitOps Integration](./11-gitops-integration.md)
    - 11.1 Configuration in Git
    - 11.2 Role Definitions
    - 11.3 Policy Management
    - 11.4 ESO Secret Distribution
    - 11.5 GitOps Boundary

### Supplementary Sections

12. [Rationale](./12-rationale.md)
    - 12.1 Why Teleport
    - 12.2 Alternative Access Brokers
    - 12.3 Alternative Credential Models
    - 12.4 Why Separate from RFC-WORKLOAD-IDENTITY

13. [Evolution](./13-evolution.md)
    - 13.1 Anticipated Extensions
    - 13.2 Scalability Considerations
    - 13.3 Migration Pathways

### Appendices

- [Appendix A: Glossary](./appendix-a-glossary.md)
  - A.1 Term Definitions
  - A.2 Diagram Index
  - A.3 Abbreviations

- [Appendix B: References](./appendix-b-references.md)
  - B.1 Normative References
  - B.2 Technology Documentation
  - B.3 Informative References
  - B.4 Internal References
  - B.5 Version History

---

## Reading Paths

### For Platform Architects

Understanding the complete PAM design:
1. [Introduction](./01-introduction.md) — Problem context
2. [Requirements](./02-requirements.md) — Constraints and invariants
3. [Architecture](./03-architecture.md) — High-level design
4. [Identity Integration](./05-identity-integration.md) — Keycloak relationship
5. [Rationale](./12-rationale.md) — Design decisions

### For Security Engineers

Evaluating security boundaries and controls:
1. [Requirements §2.4](./02-requirements.md#24-architectural-invariants) — Security invariants
2. [Architecture §3.5](./03-architecture.md#35-trust-boundaries) — Trust boundaries
3. [Session Management](./09-session-management.md) — Audit capabilities
4. [Access Requests](./10-access-requests.md) — JIT access workflow

### For DevOps/SRE Engineers

Understanding operational integration:
1. [Components](./04-components.md) — System components
2. [SSH Access](./06-ssh-access.md) — Server access
3. [Database Access](./07-database-access.md) — Database access
4. [Kubernetes Governance](./08-kubernetes-governance.md) — K8s exec access
5. [GitOps Integration](./11-gitops-integration.md) — Deployment model

### For Compliance Officers

Understanding audit and compliance capabilities:
1. [Session Management](./09-session-management.md) — Recording requirements
2. [Access Requests](./10-access-requests.md) — Approval workflows
3. [Appendix B §B.1](./appendix-b-references.md#b1-normative-references) — Compliance standards

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| — | Table of Contents | [1. Introduction →](./01-introduction.md) |

---

*End of Index — RFC-PAM-0001*
