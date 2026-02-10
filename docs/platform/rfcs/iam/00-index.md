```
RFC-IAM-0001                                                    Index
Category: Standards Track                         Federated Identity
```

# RFC-IAM-0001: Federated Identity and Access Management Architecture

[Index](#table-of-contents)

---

## RFC Metadata

| Field | Value |
|-------|-------|
| RFC ID | RFC-IAM-0001 |
| Title | Federated Identity and Access Management Architecture |
| Status | Draft |
| Category | Standards Track |
| Author | Platform Engineering |
| Created | 2026-02-10 |
| Last Updated | 2026-02-10 |
| Version | 1.0.0 |

---

## Abstract

This RFC defines the architecture for **web UI authentication** and **application-level authorization** for platform developer tools. It positions Azure Active Directory as the authoritative identity source and Keycloak as the centralized identity provider, enabling single sign-on across all platform web applications.

The architecture enforces a strict authorization hierarchy where Azure AD permissions represent an immutable ceiling that downstream systems cannot exceed. Azure AD and Keycloak operate as a conjunctive (AND) authorization gate—access requires both systems to permit the action.

### Scope Boundaries

| In Scope | Out of Scope |
|----------|--------------|
| Human users logging into web UIs | Machine/workload identity |
| Application authorization (what users can do) | Service-to-service authentication |
| OIDC/OAuth browser-based flows | SSH, database, kubectl access |
| API access via bearer tokens from OIDC | AI agent identity management |
| Platform application integration; Developer portal authentication (see RFC-DEVELOPER-PLATFORM) | Network-level access controls |

This RFC addresses **interactive human users accessing web interfaces**—not automated workloads, infrastructure access, or machine identity.

### Relationship to Other RFCs

This RFC is part of a family of platform architecture specifications:

| RFC | Domain | Scope |
|-----|--------|-------|
| **RFC-IAM-0001** (this document) | Web UI Auth & App Authorization | Human → Web Application |
| **[RFC-SECOPS-0001](../secret-ops/00-index.md)** | Secrets Management | All secrets lifecycle (Vault as central authority) |
| RFC-DEVELOPER-PLATFORM (planned) | Developer Portal | Backstage, capability-based UI, self-service |
| RFC-WORKLOAD-IDENTITY (planned) | Workload Identity | Service-to-service auth, machine identity, AI agents |
| RFC-TENANT-SECURITY (planned) | Tenant Application Security | WAF, network policies, routing, ingress protection |
| RFC-PAM (planned) | Privileged Access | SSH, database, kubectl access |

RFC-SECOPS-0001 is the authoritative specification for secrets management—not just machine secrets, but **all secrets** where Vault serves as central authority. This RFC defers to RFC-SECOPS-0001 for all secret storage, distribution, and rotation concerns.

---

## Table of Contents

### Core Sections

1. [Introduction](./01-introduction.md)
   - 1.1 Background and Context
   - 1.2 Current State Analysis
   - 1.3 Operational Challenges
   - 1.4 Motivation for This Architecture

2. [Requirements](./02-requirements.md)
   - 2.1 Problem Restatement
   - 2.2 Design Goals
   - 2.3 Non-Goals
   - 2.4 Architectural Invariants
   - 2.5 Success Criteria

3. [Architecture](./03-architecture.md)
   - 3.1 System Overview
   - 3.2 Trust Hierarchy Model
   - 3.3 Authority Domains
   - 3.4 Trust Boundaries
   - 3.5 Data Flow Model

4. [Components](./04-components.md)
   - 4.1 Azure Active Directory
   - 4.2 Keycloak Identity Provider
   - 4.3 HashiCorp Vault
   - 4.4 External Secrets Operator
   - 4.5 Crossplane
   - 4.6 Developer Portal *(Reference: RFC-DEVELOPER-PLATFORM)*
   - 4.7 Target Applications

### Domain-Specific Sections

5. [Authorization Model](./05-authorization-model.md)
   - 5.1 Permission Inheritance Principle
   - 5.2 Azure AD as Authorization Ceiling
   - 5.3 Keycloak Role Mapping
   - 5.4 Application-Level Authorization
   - 5.5 Authorization Decision Flow

6. [Secrets Management](./06-secrets-management.md) *(Defers to RFC-SECOPS-0001)*
   - 6.1 Normative Reference: RFC-SECOPS-0001
   - 6.2 Scope of This Section
   - 6.3 Identity-Bound Secrets
   - 6.4 Vault Policy Integration with Keycloak
   - 6.5 Keycloak Client Secret Coordination

7. [GitOps Integration](./07-gitops-integration.md)
   - 7.1 Declarative Configuration Model
   - 7.2 Crossplane Provider Integration
   - 7.3 Helm Chart Templating Strategy
   - 7.4 Resource Reconciliation
   - 7.5 Configuration Boundaries

8. [Application Integration](./08-application-integration.md)
   - 8.1 Integration Patterns
   - 8.2 Authentication Integration
   - 8.3 Authorization Integration
   - 8.4 Secrets Integration
   - 8.5 Crossplane Resource Integration
   - 8.6 Developer Portal Integration *(Reference: RFC-DEVELOPER-PLATFORM)*
   - 8.7 Extension Model
   - 8.8 CI/CD Integration

### Supplementary Sections

9. [Rationale](./09-rationale.md)
   - 9.1 Organizational Authority Boundaries
   - 9.2 Alternative Identity Architectures
   - 9.3 Alternative Authorization Models
   - 9.4 Alternative Secrets Management Approaches
   - 9.5 Alternative GitOps Strategies

10. [Evolution](./10-evolution.md)
    - 10.1 Anticipated Extensions
    - 10.2 Scalability Considerations
    - 10.3 Migration Pathways

### Appendices

- [Appendix A: Glossary](./appendix-a-glossary.md)
  - A.1 Term Definitions
  - A.2 ADR Index
  - A.3 Diagram Index

- [Appendix B: References](./appendix-b-references.md)
  - B.1 Normative References
  - B.2 Technology Documentation
  - B.3 Informative References
  - B.4 Internal References

---

## Reading Paths

### For Platform Architects

Understanding the complete system design:
1. [Introduction](./01-introduction.md) — Problem context
2. [Requirements](./02-requirements.md) — Constraints and invariants
3. [Architecture](./03-architecture.md) — High-level design
4. [Authorization Model](./05-authorization-model.md) — Permission hierarchy
5. [Rationale](./09-rationale.md) — Design decisions

### For Security Engineers

Evaluating security boundaries and controls:
1. [Requirements §2.4](./02-requirements.md#24-architectural-invariants) — Security invariants
2. [Architecture §3.4](./03-architecture.md#34-trust-boundaries) — Trust boundaries
3. [Authorization Model](./05-authorization-model.md) — Full section
4. [Secrets Management](./06-secrets-management.md) — Full section

### For DevOps Engineers

Understanding operational integration:
1. [Components](./04-components.md) — System components
2. [GitOps Integration](./07-gitops-integration.md) — Deployment model
3. [Application Integration](./08-application-integration.md) — Platform applications
4. [Secrets Management §6.3-6.4](./06-secrets-management.md#63-namespace-distribution) — Secret distribution

### For Application Developers

Understanding how to integrate applications:
1. [Architecture §3.1](./03-architecture.md#31-system-overview) — System overview
2. [Authorization Model §5.5](./05-authorization-model.md#55-authorization-decision-flow) — Authorization flow
3. [Application Integration §8.1](./08-application-integration.md#81-integration-patterns) — Integration patterns
4. [Glossary](./appendix-a-glossary.md) — Terminology

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| — | Table of Contents | [1. Introduction →](./01-introduction.md) |

---

*End of Index*
