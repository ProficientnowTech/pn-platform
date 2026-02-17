```
                                                            RFC-PLATARCH-0001
                                                            Category: Standards Track
                                                            Status: Draft
                                                            Platform Engineering
                                                            February 2026
```

# Platform Architecture

---

## Status of This Memo

This document specifies a standards-track architecture for platform deployment
and orchestration within the platform infrastructure. Distribution of this memo
is unlimited within the organization and to authorized external reviewers.

This document is a DRAFT and is subject to change based on review feedback.

---

## Abstract

This Request for Comments (RFC) defines the comprehensive platform architecture
for application deployment and orchestration. It establishes a capability-based
orchestration model where applications depend on capabilities rather than direct
application dependencies, centralizes shared infrastructure under platform
ownership with explicit capability contracts, mandates a canonical base chart as
the single integration mechanism for applications, and defines governance
guardrails ensuring Git as source of truth with consistent namespace, project,
and ownership boundaries.

The architecture addresses fundamental problems in platform engineering: brittle
coupling between applications, infrastructure sprawl from per-application
provisioning, inconsistent application integration patterns, and governance gaps
from ad-hoc deployment practices. The solution provides deterministic
orchestration through capability satisfaction, centralized infrastructure with
guaranteed contracts, uniform application onboarding via mandatory base chart
adoption, and enforceable governance through structural constraints.

---

## Copyright Notice

Copyright (c) 2026 Platform Engineering. All rights reserved.

---

## Document Information

| Attribute            | Value                                              |
| -------------------- | -------------------------------------------------- |
| RFC Number           | RFC-PLATARCH-0001                                  |
| Kind                 | Architecture                                       |
| Status               | Draft                                              |
| Version              | 1.0.0                                              |
| Created              | 2026-02-17                                         |
| Last Updated         | 2026-02-17                                         |
| Authors              | Platform Engineering Team                          |
| Reviewers            | Security, Infrastructure, SRE (TBD)                |
| Application Domain   | Platform Architecture, Orchestration, Governance   |

### Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-17 | Initial release consolidating P1-P4 documents |

---

## Intended Audience

This document is written for:

- Platform & Infrastructure Engineers
- Cloud / Kubernetes / GitOps Architects
- Security & Compliance Reviewers
- Application Development Teams
- Broader Engineering Organization

No prior knowledge of the internal system is assumed.

---

## Conventions and Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
[BCP 14](https://www.rfc-editor.org/info/bcp14)
[[RFC2119](https://datatracker.ietf.org/doc/html/rfc2119)]
[[RFC8174](https://datatracker.ietf.org/doc/html/rfc8174)]
when, and only when, they appear in all capitals, as shown here.

---

## Table of Contents

### Part 1: Foundation

1. [Introduction](./01-introduction.md)
   - 1.1 Problem Statement
   - 1.2 Motivation and Goals
   - 1.3 Scope and Boundaries

2. [Requirements and Invariants](./02-requirements.md)
   - 2.1 Design Principles
   - 2.2 Architectural Invariants
   - 2.3 Non-Functional Requirements

### Part 2: Architecture

3. [Core Architecture](./03-architecture.md)
   - 3.1 Capability Model Overview
   - 3.2 Conceptual Architecture
   - 3.3 System Structure

4. [Component Taxonomy](./04-components.md)
   - 4.1 Platform Components
   - 4.2 Infrastructure Components
   - 4.3 Application Components

5. [Capability Orchestration](./05-capability-orchestration.md)
   - 5.1 Event Model
   - 5.2 Execution Semantics
   - 5.3 Readiness and Failure Handling

6. [Shared Infrastructure](./06-shared-infrastructure.md)
   - 6.1 Eligibility Criteria
   - 6.2 Ownership Rules
   - 6.3 Capability Contracts
   - 6.4 Lifecycle Management

7. [Application Model](./07-application-model.md)
   - 7.1 Base Chart Mandate
   - 7.2 Capability Declarations
   - 7.3 Secrets, Configuration, and Identity
   - 7.4 Networking, Ingress, and Exposure
   - 7.5 Application Removal

### Part 3: Governance

8. [Governance and Guardrails](./08-governance-guardrails.md)
   - 8.1 Repository Structure
   - 8.2 Namespace Strategy
   - 8.3 ArgoCD Projects
   - 8.4 Ownership and Change Management

### Part 4: Rationale and Evolution

9. [Rationale and Alternatives](./09-rationale.md)
   - 9.1 Rejected Alternatives
   - 9.2 ArgoCD Relationship
   - 9.3 Explicit Prohibitions

10. [Future Considerations](./10-evolution.md)
    - 10.1 Extension Points
    - 10.2 Multi-Cluster Considerations
    - 10.3 Versioning Strategy

### Appendices

- [Appendix A: Glossary](./appendix-a-glossary.md)
- [Appendix B: References](./appendix-b-references.md)

---

## Quick Navigation

| Section | Description | Audience |
|---------|-------------|----------|
| [1. Introduction](./01-introduction.md) | Problem space and motivation | All |
| [2. Requirements](./02-requirements.md) | Design constraints and invariants | All |
| [3. Architecture](./03-architecture.md) | Capability model and system structure | Engineers, Architects |
| [4. Components](./04-components.md) | Component classification | Engineers |
| [5. Orchestration](./05-capability-orchestration.md) | Deployment sequencing mechanics | Engineers |
| [6. Shared Infrastructure](./06-shared-infrastructure.md) | Infrastructure centralization | Engineers, SRE |
| [7. Application Model](./07-application-model.md) | Application integration requirements | Engineers |
| [8. Governance](./08-governance-guardrails.md) | Platform governance rules | All |
| [9. Rationale](./09-rationale.md) | Design decisions and alternatives | Architects |
| [10. Evolution](./10-evolution.md) | Future considerations | Architects |

---

## Reading Paths

**New to the Platform?**
Start with [Introduction](./01-introduction.md) → [Requirements](./02-requirements.md) → [Architecture](./03-architecture.md)

**Application Developer?**
Focus on [Application Model](./07-application-model.md) → [Governance](./08-governance-guardrails.md) → [Glossary](./appendix-a-glossary.md)

**Platform Engineer?**
Read [Architecture](./03-architecture.md) → [Components](./04-components.md) → [Orchestration](./05-capability-orchestration.md) → [Shared Infrastructure](./06-shared-infrastructure.md)

**Understanding Design Decisions?**
Read [Requirements](./02-requirements.md) → [Rationale](./09-rationale.md) → [Evolution](./10-evolution.md)

---

## Relationship to Other RFCs

This RFC defines the foundational platform architecture. It has normative and informative relationships with several domain-specific RFCs.

### Normative Dependencies (This RFC Defers To)

| RFC | Domain | Relationship |
|-----|--------|--------------|
| [RFC-SECOPS-0001](../secret-ops/00-index.md) | Secrets Management | **Authoritative** for all secret lifecycle concerns. Section 07 of this RFC defers to RFC-SECOPS-0001 for secret provisioning, rotation, and distribution mechanics. |
| [RFC-DEPLOY-0001](../deploy-ops/00-index.md) | Deployment Orchestration | **Authoritative** for deployment mechanics. Section 05 of this RFC describes orchestration concepts; RFC-DEPLOY-0001 specifies the implementation using Argo Workflows. |

### Informative Dependencies (Domain-Specific Extensions)

| RFC | Domain | Relationship |
|-----|--------|--------------|
| [RFC-IAM-0001](../iam/00-index.md) | Web UI Authentication | Implements human identity for web applications. RFC-PLATARCH establishes identity requirements; RFC-IAM specifies Keycloak SSO implementation. |
| [RFC-WORKLOAD-IDENTITY-0001](../workload-identity/01-introduction.md) | Workload Identity | Implements machine/service identity. RFC-PLATARCH requires platform identity; RFC-WORKLOAD-IDENTITY specifies SPIFFE/SPIRE attestation-based identity. |
| [RFC-TENANT-SECURITY-0001](../tenant-security/00-index.md) | Network Security | Implements network isolation. RFC-PLATARCH requires namespace isolation; RFC-TENANT-SECURITY specifies WAF, network policies, and ingress protection. |
| [RFC-PAM-0001](../pam/00-index.md) | Privileged Access | Implements human infrastructure access. RFC-PLATARCH establishes governance boundaries; RFC-PAM specifies Teleport-based SSH, database, and kubectl access. |
| [RFC-DEVELOPER-PLATFORM-0001](../developer-platform/00-index.md) | Developer Portal | Implements developer self-service. RFC-PLATARCH defines capability consumption; RFC-DEVELOPER-PLATFORM specifies Backstage-based capability discovery and provisioning workflows. |

### Scope Boundaries

| Concern | This RFC | Delegated To |
|---------|----------|--------------|
| Secret provisioning mechanics | Declares requirements | RFC-SECOPS-0001 |
| Secret rotation policies | Declares requirements | RFC-SECOPS-0001 |
| Deployment DAG execution | Describes concepts | RFC-DEPLOY-0001 |
| Human web authentication | Declares requirements | RFC-IAM-0001 |
| Service-to-service mTLS | Declares requirements | RFC-WORKLOAD-IDENTITY-0001 |
| WAF and ingress protection | Declares requirements | RFC-TENANT-SECURITY-0001 |
| SSH/database/kubectl access | Declares requirements | RFC-PAM-0001 |
| Developer self-service UI | Declares requirements | RFC-DEVELOPER-PLATFORM-0001 |

---

## Cross-References

This RFC consolidates and supersedes the following preliminary documents:

| Document | Title | Status |
|----------|-------|--------|
| RFC-P1-01 through P1-10 | Capability Orchestration Model | Superseded by this RFC |
| RFC-P2-01 through P2-06 | Shared Infrastructure Model | Superseded by this RFC |
| RFC-P3-01 through P3-07 | Application Model | Superseded by this RFC |
| RFC-P4-01 through P4-06 | Platform Governance | Superseded by this RFC |

---

*RFC-PLATARCH-0001 — Index*
