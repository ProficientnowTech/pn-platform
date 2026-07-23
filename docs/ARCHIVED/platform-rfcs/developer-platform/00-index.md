```
RFC-DEVELOPER-PLATFORM-0001                                           Index
Category: Standards Track                            Developer Platform
```

# RFC-DEVELOPER-PLATFORM-0001: Developer Platform Architecture

[Index](#table-of-contents)

---

## RFC Metadata

| Field | Value |
|-------|-------|
| RFC ID | RFC-DEVELOPER-PLATFORM-0001 |
| Title | Developer Platform Architecture |
| Status | Draft |
| Category | Standards Track |
| Kind | Architecture |
| Author | Platform Engineering |
| Created | 2026-02-12 |
| Last Updated | 2026-02-12 |
| Version | 1.0.0 |

---

## Abstract

This RFC defines the architecture for the **unified developer platform**, providing developers with self-service access to platform capabilities through a centralized portal. The architecture positions Backstage as the developer portal framework, integrating with the platform's identity, secrets, and privileged access management systems.

The platform enables developers to discover services, create projects from templates, provision infrastructure, request access to resources, and navigate platform tools—all through a capability-based interface where users see only actions they are permitted to perform.

### Scope Boundaries

| In Scope | Out of Scope |
|----------|--------------|
| Developer portal framework (Backstage) | Authentication flows (RFC-IAM-0001) |
| Software Catalog entity model | Secrets management (RFC-SECOPS-0001) |
| Software Templates and golden paths | Privileged access implementation (RFC-PAM-0001) |
| TechDocs documentation-as-code | WAF and network policies (RFC-TENANT-SECURITY) |
| Permission framework and UI rendering | Service mesh and mTLS (RFC-WORKLOAD-IDENTITY) |
| Database provisioning workflows | Deployment orchestration (RFC-DEPLOY-OPS) |
| Event streaming management | |
| Tool library and deep linking | |
| JIT access request UI | |

This RFC addresses **how developers interact with the platform**—not the underlying implementation of authentication, secrets, or infrastructure.

### Relationship to Other RFCs

This RFC is part of a family of platform architecture specifications:

| RFC | Domain | Relationship |
|-----|--------|--------------|
| **RFC-DEVELOPER-PLATFORM-0001** (this document) | Developer Portal | How developers interact with the platform |
| [RFC-IAM-0001](../iam/00-index.md) | Identity & Access | Provides Keycloak OIDC authentication |
| [RFC-SECOPS-0001](../secret-ops/00-index.md) | Secrets Management | Provides Vault secrets for portal and plugins |
| [RFC-PAM-0001](../pam/00-index.md) | Privileged Access | Provides JIT access request backend |
| [RFC-TENANT-SECURITY](../tenant-security/00-index.md) | Application Security | Provides WAF protection and network policies |
| [RFC-WORKLOAD-IDENTITY-0001](../workload-identity/00-index.md) | Workload Identity | Service-to-service auth |
| [RFC-DEPLOY-0001](../deploy-ops/00-index.md) | Deployment | Deployment orchestration |

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
   - 3.2 Trust Boundaries
   - 3.3 Authority Domains
   - 3.4 Data Flow Model
   - 3.5 Integration Architecture

4. [Components](./04-components.md)
   - 4.1 Backstage Framework
   - 4.2 PostgreSQL Database
   - 4.3 Plugin System
   - 4.4 Integration Agents

### Domain-Specific Sections

5. [Software Catalog](./05-software-catalog.md)
   - 5.1 Entity Model
   - 5.2 Entity Discovery
   - 5.3 Ownership Model
   - 5.4 Dependency Mapping

6. [Software Templates](./06-software-templates.md)
   - 6.1 Golden Path Philosophy
   - 6.2 Template Structure
   - 6.3 Scaffolder Actions
   - 6.4 GitOps Output Pattern

7. [TechDocs](./07-techdocs.md)
   - 7.1 Documentation-as-Code Model
   - 7.2 MkDocs Integration
   - 7.3 Search Integration
   - 7.4 Catalog Integration

8. [Permission Model](./08-permission-model.md)
   - 8.1 Capability-Based Authorization
   - 8.2 Keycloak Token Integration
   - 8.3 Permission Rules
   - 8.4 UI Filtering Pattern

9. [Database Provisioning](./09-database-provisioning.md)
   - 9.1 Supported Databases
   - 9.2 Environment Tiers
   - 9.3 Provisioning Workflow
   - 9.4 Crossplane Integration

10. [Access Management](./10-access-management.md)
    - 10.1 JIT Access Model
    - 10.2 Teleport Integration
    - 10.3 Access Request Workflow
    - 10.4 Session Recording

11. [Tool Library](./11-tool-library.md)
    - 11.1 Permission-Aware Directory
    - 11.2 Deep Linking Pattern
    - 11.3 SSO Integration
    - 11.4 Context-Aware Navigation

12. [Event Streaming](./12-event-streaming.md)
    - 12.1 Kafka Topic Management
    - 12.2 Schema Registry Integration
    - 12.3 Connector Management
    - 12.4 CDC Pipeline Workflows

13. [Platform Integrations](./13-platform-integrations.md)
    - 13.1 Plugin Architecture
    - 13.2 ArgoCD Integration
    - 13.3 Grafana Integration
    - 13.4 Harbor Integration
    - 13.5 Crossplane Integration

### Supplementary Sections

14. [Rationale](./14-rationale.md)
    - 14.1 Portal Framework Selection
    - 14.2 Rejected Alternatives
    - 14.3 Design Decisions
    - 14.4 Trade-offs

15. [Evolution](./15-evolution.md)
    - 15.1 DevPods (Cloud Development Environments)
    - 15.2 AI-Assisted Development
    - 15.3 Advanced Self-Service
    - 15.4 Future Integrations

### Appendices

- [Appendix A: Glossary](./appendix-a-glossary.md)
  - A.1 Term Definitions
  - A.2 Diagram Index
  - A.3 Invariant Index

- [Appendix B: References](./appendix-b-references.md)
  - B.1 Normative References
  - B.2 Technology Documentation
  - B.3 Informative References
  - B.4 Internal References
  - B.5 Version History

---

## Reading Paths

### For Platform Architects

Understanding the complete system design:
1. [Introduction](./01-introduction.md) — Problem context
2. [Requirements](./02-requirements.md) — Constraints and invariants
3. [Architecture](./03-architecture.md) — High-level design
4. [Permission Model](./08-permission-model.md) — Authorization approach
5. [Rationale](./14-rationale.md) — Design decisions

### For Security Engineers

Evaluating security boundaries and controls:
1. [Requirements §2.4](./02-requirements.md#24-architectural-invariants) — Security invariants
2. [Architecture §3.2](./03-architecture.md#32-trust-boundaries) — Trust boundaries
3. [Permission Model](./08-permission-model.md) — Full section
4. [Access Management](./10-access-management.md) — JIT access patterns

### For DevOps Engineers

Understanding operational integration:
1. [Components](./04-components.md) — System components
2. [Software Templates](./06-software-templates.md) — GitOps output patterns
3. [Platform Integrations](./13-platform-integrations.md) — Plugin architecture
4. [Database Provisioning](./09-database-provisioning.md) — Infrastructure workflows

### For Application Developers

Understanding how to use the platform:
1. [Software Catalog](./05-software-catalog.md) — Service discovery
2. [Software Templates](./06-software-templates.md) — Project creation
3. [TechDocs](./07-techdocs.md) — Documentation
4. [Tool Library](./11-tool-library.md) — Platform tools
5. [Glossary](./appendix-a-glossary.md) — Terminology

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| — | Table of Contents | [1. Introduction →](./01-introduction.md) |

---

*End of Index — RFC-DEVELOPER-PLATFORM-0001*
