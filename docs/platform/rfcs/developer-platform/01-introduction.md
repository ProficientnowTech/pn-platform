```
RFC-DEVELOPER-PLATFORM-0001                                       Section 1
Category: Standards Track                                     Introduction
```

# 1. Introduction

[← Index](./00-index.md) | [Index](./00-index.md#table-of-contents) | [Next: Requirements →](./02-requirements.md)

---

## 1.1 Background and Context

### 1.1.1 The Developer Experience Challenge

Modern platform engineering organizations face a fundamental tension: as platforms grow in capability, they also grow in complexity. Developers need access to an increasing number of tools, services, and workflows, each with its own interface, authentication mechanism, and operational model.

This complexity manifests in several ways:

| Challenge | Description |
|-----------|-------------|
| Tool Proliferation | Multiple specialized tools for CI/CD, monitoring, logging, databases, message queues |
| Authentication Fatigue | Separate login flows for each tool, even with SSO |
| Discoverability | Difficulty finding which services exist and who owns them |
| Documentation Scatter | Documentation spread across repositories, wikis, and external sites |
| Onboarding Friction | New team members spend significant effort learning tool locations and access patterns |

### 1.1.2 The Internal Developer Platform Concept

An Internal Developer Platform (IDP) addresses these challenges by providing a unified interface through which developers interact with platform capabilities. Rather than exposing raw infrastructure and tools, an IDP presents abstractions and workflows aligned with developer mental models.

The platform concept has gained significant traction in the industry:

| Organization | Adoption |
|--------------|----------|
| CNCF | Published Platform Engineering White Paper |
| Gartner | Identified platform engineering as key trend |
| Industry | Over 3,400 organizations using Backstage |

### 1.1.3 Platform Maturity Model

Organizations typically progress through platform maturity stages:

| Stage | Characteristics |
|-------|-----------------|
| Ad-Hoc | Direct tool access, manual processes |
| Standardized | Common tools, but separate interfaces |
| Self-Service | Developer portal for common operations |
| Optimized | AI-assisted, predictive capabilities |

This RFC addresses the transition from standardized to self-service maturity.

---

## 1.2 Current State Analysis

### 1.2.1 Existing Tool Landscape

The platform currently provides developers with access to numerous tools:

| Domain | Tools |
|--------|-------|
| GitOps | ArgoCD, Kargo |
| CI/CD | Tekton, GitHub Actions |
| Monitoring | Grafana, Prometheus, Loki, Tempo |
| Databases | PostgreSQL, MongoDB, ClickHouse, Redis |
| Event Streaming | Kafka, Apicurio Registry, Kafka Connect |
| Registry | Harbor (containers), Verdaccio (npm) |
| Security | Vault, Teleport, Keycloak |
| Storage | Ceph |

### 1.2.2 Access Patterns

Developers currently access these tools through:

| Pattern | Description | Limitation |
|---------|-------------|------------|
| Direct URL access | Bookmark or navigate to tool URL | No unified entry point |
| Separate authentication | Each tool authenticates via Keycloak | Multiple login redirects |
| Manual discovery | Ask colleagues or search documentation | Knowledge siloed in teams |
| Request-based provisioning | File tickets for infrastructure | Delays in obtaining resources |

### 1.2.3 Documentation State

Documentation exists in multiple locations:

| Location | Content Type | Challenge |
|----------|--------------|-----------|
| Git repositories | API specs, runbooks | Disconnected from services |
| External wikis | Architectural docs | Stale, out of sync |
| Tool-specific docs | Vendor documentation | Generic, not organization-specific |
| Tribal knowledge | Operational procedures | Lost when team members leave |

---

## 1.3 Operational Challenges

### 1.3.1 Developer Productivity

The current state creates several productivity challenges:

| Challenge | Impact |
|-----------|--------|
| Context switching | Developers navigate between multiple tool interfaces |
| Discovery overhead | Finding the right tool or resource requires asking colleagues |
| Access delays | Infrastructure requests require manual processing |
| Documentation gaps | Developers lack visibility into service capabilities and ownership |

### 1.3.2 Platform Team Burden

Platform teams experience operational overhead from:

| Burden | Description |
|--------|-------------|
| Request processing | Manual handling of infrastructure provisioning requests |
| Access management | Responding to access requests for various tools |
| Onboarding support | Repeatedly explaining tool locations and access patterns |
| Documentation maintenance | Keeping scattered documentation current |

### 1.3.3 Security and Compliance

Current patterns create security challenges:

| Challenge | Description |
|-----------|-------------|
| Access visibility | Difficult to audit who has access to what |
| Permission sprawl | Over-permissioned access granted for convenience |
| Audit trails | Fragmented logs across multiple systems |
| Compliance evidence | Manual collection of compliance artifacts |

---

## 1.4 Motivation for This Architecture

### 1.4.1 Unified Developer Experience

The primary motivation is providing developers with a single interface for platform interactions. This interface MUST:

| Requirement | Rationale |
|-------------|-----------|
| Consolidate tool access | Reduce cognitive overhead of navigating multiple tools |
| Provide service discovery | Enable finding services, APIs, and infrastructure |
| Enable self-service | Allow common operations without platform team involvement |
| Surface documentation | Bring docs alongside the services they describe |

### 1.4.2 Capability-Based Interaction

The architecture implements a capability-based model where users see only what they can do. This approach:

| Benefit | Description |
|---------|-------------|
| Reduces confusion | Users are not presented with unavailable options |
| Simplifies UX | No permission-denied errors for attempted actions |
| Enforces security | Authorization through visibility, not blocking |
| Reflects reality | UI accurately represents user's actual capabilities |

### 1.4.3 Self-Service Within Guardrails

The platform enables developer self-service while maintaining organizational controls:

| Self-Service | Guardrail |
|--------------|-----------|
| Create projects from templates | Templates enforce organizational standards |
| Provision databases | Resource quotas and approval workflows |
| Request access to resources | Time-bounded, session-recorded access |
| Deploy applications | GitOps-only deployment model |

### 1.4.4 Integration with Platform RFCs

This architecture integrates with the platform's foundational RFCs:

| RFC | Integration Point |
|-----|-------------------|
| RFC-IAM-0001 | Keycloak provides authentication and permission claims |
| RFC-SECOPS-0001 | Vault provides secrets for portal and plugins |
| RFC-PAM-0001 | Teleport provides JIT access request backend |
| RFC-TENANT-SECURITY | BunkerWeb protects portal; network policies govern access |

---

## 1.5 Document Structure

This RFC is organized to address different audiences:

| Section | Audience | Content |
|---------|----------|---------|
| Requirements | Architects, Security | Invariants, constraints, success criteria |
| Architecture | Architects | Trust boundaries, data flow, integration |
| Components | DevOps | Backstage architecture, plugins |
| Domain Sections | Developers | Catalog, templates, tools, workflows |
| Rationale | Reviewers | Design decisions, alternatives |
| Evolution | Planners | Future capabilities |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← Index](./00-index.md) | [Table of Contents](./00-index.md#table-of-contents) | [2. Requirements →](./02-requirements.md) |

---

*End of Section 1 — RFC-DEVELOPER-PLATFORM-0001*
