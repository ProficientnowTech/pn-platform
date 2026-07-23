```
RFC-CICD-0001                                                         Index
Category: Standards Track              Argo Workflows CI/CD Architecture
```

# RFC-CICD-0001: Argo Workflows CI/CD Architecture

[Index](#table-of-contents)

---

## RFC Metadata

| Field | Value |
|-------|-------|
| RFC ID | RFC-CICD-0001 |
| Kind | Architecture |
| Title | Argo Workflows CI/CD Architecture |
| Status | Draft |
| Category | Standards Track |
| Author | Platform Engineering |
| Created | 2026-03-30 |
| Last Updated | 2026-03-30 |
| Version | 1.0.0 |

---

## Abstract

This RFC defines the architecture for continuous integration and continuous delivery within the pnow-ats-v2 monorepo. The system uses Argo Workflows as the execution engine and Argo Events as the ingestion layer to provide fully in-cluster CI/CD that operates without external CI services.

The monorepo contains 22 Nx-managed TypeScript projects and 22 Dockerfiles spanning NestJS backend services, a Next.js frontend, and shared libraries published to an in-cluster Verdaccio registry. The architecture delegates all change-detection and task-ordering decisions to Nx, translates the resulting project graph into an Argo Workflow DAG at runtime, and fans out Docker image builds via Kaniko. Deployments follow a strict GitOps model: the CI pipeline commits image tags to the infrastructure repository, and ArgoCD reconciles the desired state to the cluster.

The design eliminates CephFS from the critical path of CI execution, replaces external CI services with in-cluster workflows, and enforces a single source of truth for build ordering through the Nx project graph.

### Scope Boundaries

| In Scope | Out of Scope |
|----------|--------------|
| CI pipeline architecture for TypeScript monorepo | Application-level testing strategy |
| Nx-driven change detection and build ordering | Production promotion gating and approval workflows |
| Docker image building and registry publishing | Event gateway and security sensor architecture |
| Shared library publishing to Verdaccio | Python service CI (services outside Nx management) |
| GitOps deployment integration with ArgoCD | ArgoCD application configuration |
| Argo Events webhook ingestion | GitHub webhook endpoint security |
| Nx S3 remote cache architecture | S3 bucket provisioning and lifecycle policies |

### Relationship to Other RFCs

| RFC | Domain | Relationship |
|-----|--------|--------------|
| **RFC-CICD-0001** (this document) | CI/CD Pipeline Architecture | Defines build and delivery pipelines |
| **[RFC-SECOPS-0001](../../secret-ops/00-index.md)** | Secrets Management | Vault as authority for all CI secrets |
| **[RFC-DEPLOY-0001](../../deploy-ops/00-index.md)** | Deployment Operations | ArgoCD reconciliation and rollout strategy |

This RFC defers to RFC-SECOPS-0001 for all secret sourcing and distribution concerns. Secrets consumed by CI workflows originate from Vault via ExternalSecrets; this RFC defines only the consumption interface.

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
   - 3.2 Authority Domains
   - 3.3 Trust Boundaries
   - 3.4 PR Validation Flow
   - 3.5 Post-Merge Build Flow
   - 3.6 Data Flow Model

4. [Components](./04-components.md)
   - 4.1 Argo Events Layer
   - 4.2 Argo Workflows Engine
   - 4.3 Nx Build Orchestration
   - 4.4 DAG Generator
   - 4.5 Kaniko Image Builder
   - 4.6 Verdaccio Package Registry
   - 4.7 Harbor Container Registry
   - 4.8 GitOps Updater
   - 4.9 Notification Dispatcher

### Supplementary Sections

5. [Rationale](./05-rationale.md)
   - 5.1 Workspace Strategy
   - 5.2 Rejected Pipeline Platforms
   - 5.3 Rejected Execution Models
   - 5.4 Rejected Cache Strategies

6. [Evolution](./06-evolution.md)
   - 6.1 Anticipated Extensions
   - 6.2 Extension Points
   - 6.3 Deprecation Paths

### Appendices

- [Appendix A: Glossary](./appendix-a-glossary.md)
  - A.1 Term Definitions
  - A.2 Diagram Index

- [Appendix B: References](./appendix-b-references.md)
  - B.1 Normative References
  - B.2 Technology Documentation
  - B.3 Internal References
  - B.4 Version History

---

## Reading Paths

### For Platform Architects

Understanding the complete CI/CD system design:
1. [Introduction](./01-introduction.md) -- Problem context
2. [Requirements](./02-requirements.md) -- Constraints and invariants
3. [Architecture](./03-architecture.md) -- Pipeline flows and trust boundaries
4. [Rationale](./05-rationale.md) -- Design decisions and rejected alternatives

### For DevOps Engineers

Understanding operational integration:
1. [Components](./04-components.md) -- All system components and failure modes
2. [Architecture](./03-architecture.md) -- Pipeline execution model
3. [Evolution](./06-evolution.md) -- Future extension points

### For Application Developers

Understanding how CI affects the development workflow:
1. [Architecture 3.4](./03-architecture.md) -- PR validation flow
2. [Components 4.3](./04-components.md) -- Nx build orchestration
3. [Glossary](./appendix-a-glossary.md) -- Terminology

---

## Conformance Language

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 [RFC2119] [RFC8174] when, and only when, they appear in all capitals.

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| -- | Table of Contents | [1. Introduction -->](./01-introduction.md) |

---

*End of Index -- RFC-CICD-0001*
