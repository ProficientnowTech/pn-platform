```
RFC-PLATARCH-0001                                              Section 9
Category: Standards Track                       Rationale & Alternatives
```

# 9. Rationale and Alternatives

[← Governance](./08-governance-guardrails.md) | [Index](./00-index.md#table-of-contents) | [Next: Evolution →](./10-evolution.md)

---

## 9.1 Overview

This section explains the rationale behind key architectural decisions and documents alternatives that were considered and rejected. Understanding why decisions were made helps prevent re-litigation and guides future evolution.

---

## 2. Relationship with ArgoCD

### 2.1 Why ArgoCD Is Used

ArgoCD is the GitOps engine for the platform. ArgoCD provides:
- Continuous reconciliation of cluster state toward Git state
- Declarative application definitions
- Drift detection and correction
- Rollback capabilities
- Multi-cluster support

ArgoCD is a mature, well-supported tool that implements GitOps principles effectively.

### 2.2 What ArgoCD Does

ArgoCD is responsible for:
- Syncing manifests from Git to cluster
- Detecting drift between desired and actual state
- Providing visibility into application state
- Managing application lifecycles within its scope
- Handling rollbacks when needed

ArgoCD operates at the manifest level. It applies Kubernetes resources.

### 2.3 What ArgoCD Does NOT Do

ArgoCD does not:
- Sequence deployments based on dependencies
- Understand capability semantics
- Determine when applications are ready to serve
- Coordinate cross-application concerns
- Provide semantic readiness beyond pod status

ArgoCD is not an orchestrator. It is a reconciliation engine.

### 2.4 The Orchestrator-ArgoCD Relationship

The orchestrator and ArgoCD have complementary roles:

| Concern | Owner |
|---------|-------|
| When to deploy | Orchestrator |
| How to deploy | ArgoCD |
| Capability dependencies | Orchestrator |
| Manifest application | ArgoCD |
| Semantic readiness | Orchestrator |
| Resource existence | ArgoCD |

The orchestrator tells ArgoCD when to sync. ArgoCD performs the sync.

### 2.5 Why Not ArgoCD Alone

ArgoCD alone is insufficient because:

**Sync waves are not expressive enough.** Sync waves provide coarse ordering within an Application but cannot express conditional dependencies across applications.

**Health checks are not semantic.** ArgoCD health checks verify resource state, not capability readiness.

**No cross-application coordination.** ArgoCD manages applications independently. It has no concept of applications depending on other applications' capabilities.

**No capability model.** ArgoCD has no concept of capabilities. It manages resources.

The orchestrator provides the capability layer that ArgoCD lacks.

### 2.6 Why Not Replace ArgoCD

ArgoCD is not replaced because:

**Mature reconciliation engine.** ArgoCD does reconciliation well. Replacing it would duplicate effort.

**Ecosystem integration.** ArgoCD integrates with many tools and workflows.

**Community support.** ArgoCD is actively maintained with a large user base.

**Separation of concerns.** Orchestration and reconciliation are separate concerns. Separate tools for separate concerns is good architecture.

The platform extends ArgoCD rather than replacing it.

---

## 3. Rejected Alternatives

### 3.1 Alternative: Application-Level Dependency Management

**Description:** Each application manages its own dependencies through init containers, retry logic, or health check waits.

**Rejection rationale:**
- Distributes orchestration logic across applications
- Makes dependency graph implicit and undiscoverable
- Prevents platform-level reasoning about dependencies
- Creates inconsistent dependency handling
- Embeds infrastructure knowledge in applications

Application-level dependency management is an anti-pattern. It is explicitly prohibited.

### 3.2 Alternative: Sync Waves for All Ordering

**Description:** Use ArgoCD sync waves to order all deployments.

**Rejection rationale:**
- Sync waves are numeric, not semantic
- Sync waves cannot express conditional dependencies
- Sync waves work within Applications, not across them
- Sync waves cannot wait for capability readiness
- Sync waves create maintenance burden as dependencies change

Sync waves are useful within Applications but insufficient for platform orchestration.

### 3.3 Alternative: Kubernetes Operators for Orchestration

**Description:** Build orchestration as a Kubernetes operator that watches custom resources.

**Consideration:** This is the implementation pattern, not an alternative. The orchestrator is implemented as an operator. The rejection is of using operators without the capability model.

**If capability model were rejected:**
- No semantic understanding of dependencies
- Operators would manage resources, not capabilities
- Same limitations as ArgoCD alone

The capability model is the essential abstraction, regardless of implementation pattern.

### 3.4 Alternative: External Orchestration Tools

**Description:** Use external orchestration tools (Temporal, Airflow, etc.) for deployment coordination.

**Rejection rationale:**
- External tools create additional infrastructure
- External tools don't understand Kubernetes semantics
- Integration between external tools and ArgoCD adds complexity
- External tools operate on different abstractions

Orchestration should be Kubernetes-native and integrated with the GitOps model.

### 3.5 Alternative: Multiple Base Charts

**Description:** Allow different base charts for different application types.

**Rejection rationale:**
- Multiple charts fragment integration
- Multiple charts require multiple maintenance streams
- Multiple charts create inconsistent behavior
- Platform evolution requires coordinating multiple charts
- Governance gaps where charts differ

Single base chart is essential for uniform integration. One chart, one integration model.

### 3.6 Alternative: Per-Application Infrastructure

**Description:** Allow applications to provision their own infrastructure.

**Rejection rationale:**
- Duplicates operational burden
- Creates inconsistent infrastructure management
- Prevents platform-level optimization
- Fragments security governance
- Makes infrastructure invisible to platform

Shared infrastructure is mandatory for the classes of infrastructure that qualify.

### 3.7 Alternative: Implicit Capability Discovery

**Description:** Infer capabilities from deployed resources rather than explicit declaration.

**Rejection rationale:**
- Inference is unreliable
- Inference creates hidden dependencies
- Inference cannot distinguish intended from accidental
- Inference prevents validation before deployment
- Implicit dependencies are undiscoverable

Explicit declaration is mandatory. No capability inference.

---

## 4. Explicit Prohibitions

### 4.1 Prohibition: Application-to-Application Dependencies

Applications MUST NOT depend on other applications. Applications depend on capabilities.

**Rationale:** Application dependencies create tight coupling. If A depends on B, changes to B may break A. If A depends on the capability B provides, A is insulated from B's implementation changes.

**Enforcement:** The orchestrator does not accept application references in dependency declarations. Only capability references are valid.

### 4.2 Prohibition: Circular Dependencies

Circular capability dependencies MUST NOT exist. If A requires B and B requires A, neither can be deployed.

**Rationale:** Circular dependencies cannot be resolved. There is no deployment order that satisfies both requirements first.

**Enforcement:** The orchestrator detects cycles during dependency resolution and rejects configurations with cycles.

### 4.3 Prohibition: Undeclared Capabilities

Capabilities MUST NOT be provided or consumed without declaration.

**Rationale:** Undeclared capabilities are invisible to orchestration. They create hidden coupling. They cannot be governed.

**Enforcement:** Only declared capabilities participate in orchestration. Undeclared capabilities are not registered, not waited for, not satisfied.

### 4.4 Prohibition: Base Chart Bypass

Applications MUST NOT integrate without the base chart.

**Rationale:** The base chart is the single integration point. Bypassing it creates non-standard applications that cannot be governed uniformly.

**Enforcement:** Deployment validation verifies base chart usage. Applications without the base chart are rejected.

### 4.5 Prohibition: Direct Infrastructure Access

Applications MUST NOT access infrastructure directly.

**Rationale:** Direct access bypasses capability contracts. It creates hidden dependencies. It prevents infrastructure evolution.

**Enforcement:** Network policies and access controls prevent direct access. Capability interfaces are the only access path.

### 4.6 Prohibition: Application-Owned Operators

Applications MUST NOT install or manage operators.

**Rationale:** Operators have cluster-wide effects. Multiple operators for the same purpose conflict. Operator management requires expertise applications should not need.

**Enforcement:** Applications lack permissions to install operators. Operator installation is a platform function.

### 4.7 Prohibition: CRD Creation by Applications

Applications MUST NOT create CRDs.

**Rationale:** CRDs extend the Kubernetes API. API extensions are platform decisions. Uncoordinated CRD creation creates schema conflicts.

**Enforcement:** Applications lack permissions to create CRDs. CRD creation is a platform function.

### 4.8 Prohibition: Secret Creation by Applications

Applications MUST NOT create secrets.

**Rationale:** Application-created secrets bypass platform secret management. They are not rotated, not audited, not governed.

**Enforcement:** Secret creation by applications is blocked. Secrets come from platform secret management.

---

## 5. Design Trade-offs

### 5.1 Complexity vs. Correctness

The capability model adds complexity. Applications must declare capabilities. The orchestrator must process declarations. More moving parts exist.

**Trade-off accepted:** Correctness is more valuable than simplicity. Incorrect deployments cause failures. The complexity of the capability model prevents failures.

### 5.2 Flexibility vs. Consistency

The single base chart reduces flexibility. Applications cannot use custom integration patterns.

**Trade-off accepted:** Consistency enables governance. Flexibility creates fragmentation. Platform value comes from consistent behavior.

### 5.3 Autonomy vs. Governance

Centralizing infrastructure reduces application team autonomy. Teams cannot make arbitrary infrastructure choices.

**Trade-off accepted:** Governance enables platform guarantees. Autonomy creates ungoverned sprawl. Platform value comes from governed infrastructure.

### 5.4 Explicitness vs. Convenience

Explicit declaration requires effort. Applications must declare every capability.

**Trade-off accepted:** Explicitness enables reasoning. Convenience creates hidden behavior. Platform value comes from knowable dependencies.

---

## 6. Why These Decisions Matter

### 6.1 Determinism

The decisions produce deterministic behavior. Same inputs produce same outputs. Determinism enables testing, debugging, and reasoning.

Rejected alternatives produce non-determinism. Timing-dependent behavior, race conditions, and undefined order are characteristics of rejected approaches.

### 6.2 Auditability

The decisions produce auditable systems. Every dependency is declared. Every change is in Git. Every deployment is orchestrated.

Rejected alternatives produce opaque systems. Hidden dependencies, implicit behavior, and undocumented coupling are characteristics of rejected approaches.

### 6.3 Evolvability

The decisions enable evolution. Capabilities abstract implementations. Contracts version changes. Central integration enables coordinated updates.

Rejected alternatives impede evolution. Tight coupling, fragmented integration, and undeclared dependencies resist change.

---

## 7. Summary

### 7.1 ArgoCD Relationship

| ArgoCD Does | Orchestrator Does |
|-------------|-------------------|
| Manifest reconciliation | Deployment sequencing |
| Drift detection | Capability satisfaction |
| Resource health | Semantic readiness |

### 7.2 Rejected Alternatives

| Alternative | Rejection Reason |
|-------------|------------------|
| Application-level dependencies | Distributes logic, creates implicit coupling |
| Sync waves only | Not expressive enough |
| External orchestration | Additional infrastructure, different abstractions |
| Multiple base charts | Fragments integration |
| Per-application infrastructure | Duplicates burden, fragments governance |
| Implicit capabilities | Unreliable, undiscoverable |

### 7.3 Prohibitions

| Prohibited | Rationale |
|------------|-----------|
| App-to-app dependencies | Tight coupling |
| Circular dependencies | Unresolvable |
| Undeclared capabilities | Invisible to governance |
| Base chart bypass | Non-standard integration |
| Direct infrastructure access | Bypasses contracts |
| Application operators/CRDs | Platform authority |
| Application secret creation | Bypasses management |

### 7.4 Trade-offs Accepted

| Sacrificed | Gained |
|------------|--------|
| Simplicity | Correctness |
| Flexibility | Consistency |
| Autonomy | Governance |
| Convenience | Explicitness |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 8. Governance](./08-governance-guardrails.md) | [Table of Contents](./00-index.md#table-of-contents) | [10. Evolution →](./10-evolution.md) |

---

*End of Section 9 — RFC-PLATARCH-0001*
