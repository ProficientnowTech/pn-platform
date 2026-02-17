```
RFC-PLATARCH-0001                                              Section 2
Category: Standards Track                      Requirements & Invariants
```

# 2. Requirements and Invariants

[← Introduction](./01-introduction.md) | [Index](./00-index.md#table-of-contents) | [Next: Architecture →](./03-architecture.md)

---

## 2.1 Overview

This section defines the requirements and invariants that govern the platform architecture. Invariants are properties that must always hold. Requirements are conditions that must be satisfied. Together, they form the constraints within which the architecture operates.

---

## 2. Orchestration Invariants

### 2.1 Invariant: Capability Satisfaction Before Deployment

An application MUST NOT be deployed until all capabilities it requires are satisfied. This invariant is absolute. There are no exceptions for convenience, urgency, or special cases. The orchestrator enforces this invariant mechanically.

If an application declares that it requires capability X, and capability X is not satisfied, deployment does not proceed. The orchestrator does not attempt deployment hoping for success. The orchestrator waits for capability satisfaction.

### 2.2 Invariant: Deterministic Orchestration

Given identical inputs, orchestration MUST produce identical outputs. The order in which applications are deployed MUST be determined solely by capability dependencies, not by timing, concurrency, or external factors.

Determinism means reproducibility. If the platform is deployed twice from the same Git state, the orchestration sequence must be the same. Determinism enables debugging, testing, and reasoning about platform behavior.

### 2.3 Invariant: Failure Isolation

Failure of one application MUST NOT cause failure of other applications, except through declared capability dependencies. If application A fails but does not provide capabilities that application B requires, application B continues operating.

Failure isolation prevents cascading failures. The blast radius of a failure is limited to the failing application and applications that explicitly depend on capabilities it provides. Implicit dependencies do not propagate failure.

### 2.4 Invariant: Explicit Dependencies Only

All dependencies MUST be explicitly declared. The orchestrator MUST NOT infer dependencies. If a dependency is not declared, it does not exist from the orchestrator's perspective.

Explicit declaration prevents hidden coupling. Applications cannot depend on timing. Applications cannot depend on deployment order unless that order is expressed through capability dependencies. What is not declared is not depended upon.

### 2.5 Invariant: Event Idempotency

All state-changing operations MUST be idempotent. Processing the same event multiple times MUST produce the same result as processing it once. Idempotency is required because events may be redelivered.

Idempotency enables retry and recovery. When failures occur, operations can be retried without fear of duplicate effects. The system converges to correct state regardless of how many times it processes a given event.

---

## 3. Infrastructure Invariants

### 3.1 Invariant: Platform Ownership

Shared infrastructure MUST be owned by the platform team. Applications MUST NOT own infrastructure that other applications consume. Ownership is not transferable to applications.

Platform ownership ensures central governance. The platform team makes infrastructure decisions, performs maintenance, coordinates upgrades, and manages lifecycle. Applications consume infrastructure; they do not control it.

### 3.2 Invariant: Contract Stability

Capability contracts MUST be stable. Once a contract is published, it MUST NOT be changed in ways that break existing consumers. Contract evolution follows versioning rules.

Contract stability enables consumer investment. Applications that integrate with a capability can trust that the integration will continue to work. Breaking changes follow formal deprecation processes.

### 3.3 Invariant: Consumer Independence

Applications MUST NOT depend on other applications. Applications depend on capabilities. If application A requires something that application B provides, application A declares a dependency on the capability, not on application B.

Consumer independence enables substitution. If a different provider can satisfy the same capability, consumers are unaffected by the change. Providers can be replaced without consumer changes.

### 3.4 Invariant: Single Source of Truth

Each capability MUST have exactly one authoritative provider within a given scope. Multiple providers claiming the same capability create ambiguity. The orchestrator cannot resolve ambiguous capability provision.

Single source prevents conflicts. When a consumer requires a capability, there is exactly one provider to satisfy that requirement. Resolution is deterministic.

---

## 4. Application Invariants

### 4.1 Invariant: Base Chart Usage

All platform applications MUST use the canonical base chart. There are no alternative integration mechanisms. Applications that do not use the base chart are not platform applications.

Base chart usage ensures uniform integration. Every application integrates through the same mechanism. Integration behavior is consistent. Consistency enables platform-wide reasoning.

### 4.2 Invariant: Capability Declaration

Applications MUST declare all capabilities they require and all capabilities they provide. Undeclared requirements are not satisfied. Undeclared provisions are not registered.

Declaration enables orchestration. The orchestrator operates on declared capabilities. What is not declared does not exist in the orchestration model.

### 4.3 Invariant: Secret Declaration

Applications MUST declare all secrets they require. Applications MUST NOT create secrets. The platform provides secrets according to declarations.

Secret declaration ensures central management. All secrets are tracked, rotated, and audited by the platform. Application-created secrets bypass this governance.

### 4.4 Invariant: Platform Identity

Applications MUST use platform-assigned identity. Applications MUST NOT create or manage their own identity credentials. Identity is a platform function.

Platform identity enables access control. The platform knows who each application is. Access decisions are based on platform-assigned identity.

---

## 5. Governance Invariants

### 5.1 Invariant: Git as Source of Truth

All platform state MUST be derivable from Git. State that exists only at runtime is drift. Drift MUST be corrected to match Git.

Git as source of truth enables recovery, audit, and review. The platform can be reconstructed from Git. Every change is recorded with history.

### 5.2 Invariant: Single Ownership

Every resource MUST have exactly one owner. Joint ownership is prohibited. Unowned resources are platform-owned by default.

Single ownership prevents conflicts. When decisions must be made about a resource, exactly one party has authority. Authority is clear.

### 5.3 Invariant: Namespace Isolation

Namespaces MUST provide meaningful isolation. Resources in different namespaces MUST NOT access each other without explicit authorization.

Namespace isolation prevents lateral movement. Compromise of one namespace does not automatically compromise others.

### 5.4 Invariant: Permission Minimization

ArgoCD projects MUST have minimum necessary permissions. No project may have permissions beyond what is required for its purpose.

Permission minimization limits blast radius. If a project is compromised, damage is limited to what the project can access.

---

## 6. Non-Functional Requirements

### 6.1 Reliability Requirements

**R-REL-01:** The orchestrator MUST continue operating despite individual application failures.

**R-REL-02:** The platform MUST recover from transient failures without manual intervention.

**R-REL-03:** Shared infrastructure MUST meet availability guarantees specified in capability contracts.

**R-REL-04:** Backup and restore procedures MUST exist for all stateful shared infrastructure.

### 6.2 Security Requirements

**R-SEC-01:** All inter-service communication MUST be encrypted.

**R-SEC-02:** All exposed services MUST require authentication.

**R-SEC-03:** Secrets MUST NOT appear in logs, error messages, or diagnostic output.

**R-SEC-04:** Network policies MUST default to deny with explicit allowlisting.

**R-SEC-05:** Certificate management MUST be automated with no manual rotation.

### 6.3 Auditability Requirements

**R-AUD-01:** All changes to the platform MUST be traceable to a Git commit.

**R-AUD-02:** All deployment actions MUST be logged with actor identity and timestamp.

**R-AUD-03:** All capability state changes MUST be recorded.

**R-AUD-04:** All secret access MUST be auditable.

### 6.4 Operational Requirements

**R-OPS-01:** Platform components MUST expose health endpoints.

**R-OPS-02:** Platform components MUST emit structured logs.

**R-OPS-03:** Platform components MUST expose metrics in standard format.

**R-OPS-04:** Application deployment MUST NOT require manual steps beyond Git commits.

---

## 7. Design Goals

### 7.1 Goal: Declarative Over Imperative

The platform prefers declarative specifications over imperative procedures. Applications declare what they need. The platform provides it. Applications do not execute provisioning scripts.

Declarative systems are verifiable. A declaration can be validated before execution. An imperative script can only be validated by running it.

### 7.2 Goal: Convention Over Configuration

The platform establishes conventions that reduce configuration burden. When a convention exists, applications follow it by default. Configuration is for exceptions.

Conventions reduce cognitive load. Applications do not reinvent patterns. Patterns are platform-provided.

### 7.3 Goal: Fail Fast Over Fail Slow

Errors SHOULD be detected at the earliest possible point. Validation failures at commit time are better than deployment failures. Deployment failures are better than runtime failures.

Fast failure reduces blast radius. Problems caught early affect fewer users and require less recovery effort.

### 7.4 Goal: Explicit Over Implicit

Dependencies, configurations, and behaviors SHOULD be explicit. Implicit behavior creates surprise. Explicit behavior creates predictability.

Explicit systems are debuggable. When behavior is explicit, operators can trace cause to effect.

### 7.5 Goal: Automation Over Manual Process

Repeatable tasks SHOULD be automated. Manual processes introduce error and variation. Automation produces consistency.

Automation enables scale. Manual processes do not scale with platform growth.

---

## 8. Eligibility Criteria

### 8.1 Shared Infrastructure Eligibility

Infrastructure is eligible for shared status when:

**E-SI-01:** Multiple applications require the same infrastructure capability.

**E-SI-02:** The infrastructure requires specialized operational expertise.

**E-SI-03:** Per-application deployment would create unjustified duplication.

**E-SI-04:** The infrastructure can be meaningfully isolated between tenants.

**E-SI-05:** Platform team can commit to required guarantees.

### 8.2 Platform Application Eligibility

An application is eligible for platform deployment when:

**E-PA-01:** The application uses the canonical base chart.

**E-PA-02:** The application declares all required capabilities.

**E-PA-03:** The application declares all provided capabilities.

**E-PA-04:** The application's secrets are declared, not embedded.

**E-PA-05:** The application complies with platform security policies.

---

## 9. Summary

### 9.1 Invariant Categories

| Category | Core Principle |
|----------|----------------|
| Orchestration | Capability satisfaction gates deployment |
| Infrastructure | Platform ownership with stable contracts |
| Application | Base chart mandate with explicit declarations |
| Governance | Git as source of truth with structural boundaries |

### 9.2 Key Requirements

| Area | Count | Focus |
|------|-------|-------|
| Reliability | 4 | Resilience and recovery |
| Security | 5 | Encryption, authentication, secrets |
| Auditability | 4 | Traceability and logging |
| Operational | 4 | Observability and automation |

### 9.3 Design Principles

- Declarative over imperative
- Convention over configuration
- Fail fast over fail slow
- Explicit over implicit
- Automation over manual process

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 1. Introduction](./01-introduction.md) | [Table of Contents](./00-index.md#table-of-contents) | [3. Architecture →](./03-architecture.md) |

---

*End of Section 2 — RFC-PLATARCH-0001*
