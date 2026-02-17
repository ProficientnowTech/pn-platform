```
RFC-PLATARCH-0001                                              Section 5
Category: Standards Track                       Capability Orchestration
```

# 5. Capability Orchestration

[← Components](./04-components.md) | [Index](./00-index.md#table-of-contents) | [Next: Shared Infrastructure →](./06-shared-infrastructure.md)

---

> **Normative Reference:** This section describes orchestration concepts. Implementation details using Argo Workflows DAG-based deployment are specified in [RFC-DEPLOY-0001](../deploy-ops/00-index.md).

## 5.1 Overview

This section defines how the platform orchestrates deployments based on capability satisfaction. It covers readiness semantics, the event model, execution semantics, and failure handling. These mechanisms ensure that applications are deployed in correct order and that failures are handled without corrupting system state.

---

## 2. Readiness and Correctness

### 2.1 The Readiness Problem

Kubernetes defines readiness for pods: a pod is ready when it passes its readiness probe. But pod readiness is not capability readiness. A pod may be running, passing health checks, and accepting connections, yet the capability it provides may not be functional.

Capability readiness requires semantic understanding. A database pod is ready in Kubernetes terms when the container is running. The database capability is ready when the database has completed initialization, accepted its schema, and can serve queries. These are different conditions.

### 2.2 Semantic Readiness

Semantic readiness means the capability is functionally available. Semantic readiness conditions vary by capability type:

**Database readiness:** Database accepts connections, schema is applied, replication is synchronized.

**Message queue readiness:** Queue accepts messages, consumers can subscribe, delivery is functioning.

**Identity service readiness:** Authentication endpoints respond, token issuance works, identity federation is active.

Semantic readiness is defined by the capability provider. Providers publish readiness conditions in their capability registrations.

### 2.3 Readiness Verification

Readiness must be verified, not assumed. The orchestrator does not trust that a capability is ready because its pods are running. The orchestrator verifies readiness through defined mechanisms:

**Health endpoints:** Capability-specific health checks that verify functional readiness.

**Readiness probes:** Custom probes that test capability-specific conditions.

**Status fields:** Custom resource status fields that indicate capability state.

Verification is continuous. Readiness can change. A capability that was ready may become unready. The orchestrator monitors readiness continuously.

### 2.4 Correctness Through Ordering

Correct orchestration ensures applications are deployed only when their requirements are satisfied. This ordering produces correctness:

1. Applications without requirements are deployed first
2. Applications whose requirements are satisfied are deployed next
3. Applications whose requirements are unsatisfied wait

This ordering is deterministic. Given the same capability graph and the same starting state, the orchestrator produces the same deployment sequence.

### 2.5 Determinism Guarantees

The orchestrator guarantees deterministic behavior:

**Same inputs, same outputs:** Given identical Git state and identical cluster state, orchestration produces identical results.

**No race conditions:** The order of deployments is determined by capability dependencies, not by timing.

**Reproducible sequences:** The deployment sequence can be predicted from the dependency graph.

Determinism enables testing. If orchestration is deterministic, it can be tested. If orchestration is random, testing is meaningless.

---

## 3. Event Model

### 3.1 Event-Driven Orchestration

The orchestrator operates on events. Events signal state changes. State changes trigger orchestration decisions.

Event-driven operation means the orchestrator is reactive. It responds to changes rather than polling for changes. Reactive operation is efficient and scalable.

### 3.2 Event Types

The orchestrator processes these event types:

**Capability Registered:** A provider has registered a new capability. New capabilities may satisfy pending requirements.

**Capability Ready:** A capability has become ready. Ready capabilities may enable waiting deployments.

**Capability Unready:** A capability has become unready. This may affect consumers but does not trigger automatic remediation.

**Capability Removed:** A capability has been removed. Consumers depending on this capability are affected.

**Deployment Requested:** A Git change has introduced a new deployment. The orchestrator evaluates requirements.

**Deployment Completed:** A deployment has finished. The orchestrator updates capability state.

**Deployment Failed:** A deployment has failed. The orchestrator handles the failure.

### 3.3 Event Properties

Events have the following properties:

**Immutable:** Events cannot be modified after emission. Events are facts.

**Ordered:** Events have a defined order within their scope. Order enables causality reasoning.

**Idempotent handling:** Processing an event multiple times produces the same result as processing it once.

**Durable:** Events are persisted. Events survive orchestrator restart.

### 3.4 Event Flow

Events flow through the system:

1. State change occurs (Git commit, pod ready, etc.)
2. Event is emitted
3. Event is persisted
4. Orchestrator processes event
5. Orchestrator updates internal state
6. Orchestrator emits consequent events or triggers actions

### 3.5 Event Ordering Guarantees

Events maintain causal ordering:

- Events from a single source are processed in emission order
- Events affecting the same capability are processed in order
- Cross-capability events may be processed concurrently

Causal ordering ensures correctness. Effects follow causes.

---

## 4. Execution Semantics

### 4.1 Deployment Trigger

A deployment is triggered when:

1. A deployment request exists (from Git)
2. All required capabilities are satisfied
3. The deployment has not already completed

When all conditions are met, the orchestrator triggers the deployment through ArgoCD.

### 4.2 Deployment Execution

Deployment execution is delegated to ArgoCD. The orchestrator does not execute deployments directly. The orchestrator's role is to determine when deployments should execute.

Execution flow:
1. Orchestrator signals ArgoCD to sync
2. ArgoCD applies manifests to cluster
3. Kubernetes creates resources
4. Resources reach ready state
5. Capability provider signals readiness
6. Orchestrator observes readiness

### 4.3 Deployment Completion

A deployment is complete when:

**Success:** All resources are created, all readiness conditions are met, capability is registered as ready.

**Failure:** Deployment fails to complete within timeout, resources fail to reach ready state, capability cannot be provided.

Completion is binary. A deployment is either complete-success or complete-failure. There is no partial completion.

### 4.4 Atomicity

Deployments are atomic at the application level. Either all of an application's resources are deployed, or none are. Partial deployment is a failure state.

Atomicity is enforced by ArgoCD sync semantics. The orchestrator does not provide additional atomicity guarantees.

### 4.5 Idempotency

Deployment execution is idempotent. Triggering the same deployment multiple times produces the same result as triggering it once.

Idempotency enables retry. If a trigger fails to reach ArgoCD, it can be retried without risk of duplicate effects.

### 4.6 Ordering Constraints

The orchestrator enforces ordering constraints:

**Requirement constraint:** An application cannot be deployed before its required capabilities are satisfied.

**Provision constraint:** A capability is not provided until its provider deployment completes successfully.

**No cycle constraint:** Circular dependencies cannot be satisfied. Cycles are detected and rejected.

---

## 5. Failure and Recovery

### 5.1 Failure Categories

Failures are categorized by scope and recoverability:

**Transient failures:** Temporary conditions that resolve without intervention. Network glitches, temporary resource exhaustion.

**Persistent failures:** Conditions that require intervention. Misconfiguration, resource conflicts, missing dependencies.

**Partial failures:** Some components succeed while others fail. Requires careful handling to avoid inconsistent state.

### 5.2 Failure Detection

Failures are detected through:

**Deployment timeouts:** Deployments that do not complete within expected time are considered failed.

**Health check failures:** Components that fail health checks indicate failure.

**Error events:** Kubernetes events indicating errors are processed.

**Explicit failure signals:** Components may explicitly signal failure conditions.

### 5.3 Failure Handling Principles

Failure handling follows these principles:

**Fail fast:** Detect failures early. Do not allow failing deployments to continue indefinitely.

**Fail loud:** Make failures visible. Failures must be logged, alerted, and surfaced.

**Fail safe:** Failures must not corrupt state. Failing deployments must not leave partial state.

**Isolate failures:** Failures must not cascade. One application's failure must not cause other applications to fail (unless they depend on the failing capability).

### 5.4 Transient Failure Recovery

Transient failures are handled through retry:

1. Failure is detected
2. Backoff period is observed
3. Deployment is retried
4. If successful, normal flow resumes
5. If failed, retry continues up to limit
6. If limit exceeded, failure becomes persistent

Retry is automatic. The orchestrator retries without manual intervention.

### 5.5 Persistent Failure Handling

Persistent failures require intervention:

1. Failure is detected and categorized as persistent
2. Alert is raised
3. Deployment is marked as failed
4. Dependent deployments are blocked
5. Intervention corrects the failure
6. Deployment is retriggered (manually or through Git change)

Persistent failures do not block the entire platform. Only dependent deployments are blocked.

### 5.6 Partial Failure Handling

Partial failures are the most complex case:

1. Some components of a deployment succeed
2. Other components fail
3. The deployment cannot be considered successful
4. Rolling back successful components may be required

Partial failures are handled by ArgoCD sync semantics. The orchestrator treats the deployment as failed.

### 5.7 Recovery Verification

After recovery, state must be verified:

1. All expected resources exist
2. All resources are in expected state
3. Capabilities are correctly registered
4. Downstream dependencies are satisfied

Verification ensures that recovery is complete. Incomplete recovery is continued failure.

---

## 6. Dependency Resolution

### 6.1 Resolution Algorithm

Dependency resolution determines deployment order:

1. Build capability dependency graph from declarations
2. Detect cycles (cycles are errors)
3. Topologically sort the graph
4. Deploy in topological order, respecting capability satisfaction

The algorithm is deterministic. Same graph produces same order.

### 6.2 Cycle Detection

Cycles are detected before deployment begins:

- A requires B, B requires A → cycle
- A requires B, B requires C, C requires A → cycle

Cycles cannot be resolved. Cycles are configuration errors that must be fixed.

### 6.3 Optional Dependencies

Optional dependencies modify resolution:

- Required dependencies must be satisfied before deployment
- Optional dependencies are satisfied if available but do not block deployment

Applications specify whether each requirement is required or optional.

### 6.4 Dependency Updates

Dependencies can change:

**New requirement added:** Application must wait for the new requirement if it is not yet satisfied.

**Requirement removed:** No blocking effect. The formerly required capability may or may not be present.

**Provider changes:** If a provider is replaced, consumers continue to function if the replacement satisfies the same capability.

---

## 7. Observability

### 7.1 Orchestration Metrics

The orchestrator exposes metrics:

- Deployments pending
- Deployments in progress
- Deployments completed (success/failure)
- Capability satisfaction rate
- Dependency resolution time
- Deployment duration

Metrics enable monitoring and capacity planning.

### 7.2 Orchestration Events

The orchestrator emits events:

- Capability registered/ready/unready/removed
- Deployment triggered/completed/failed
- Dependency satisfied/unsatisfied
- Retry initiated/exhausted

Events enable debugging and audit.

### 7.3 Orchestration Logs

The orchestrator logs:

- All state transitions
- All decisions with rationale
- All failures with context
- All external interactions

Logs enable post-hoc analysis.

---

## 8. Summary

### 8.1 Readiness Model

| Concept | Description |
|---------|-------------|
| Semantic readiness | Capability is functionally available, not just running |
| Readiness verification | Continuous verification through defined mechanisms |
| Correctness through ordering | Deployments proceed only when requirements are met |

### 8.2 Event Model

| Event | Trigger |
|-------|---------|
| Capability Registered | Provider registers capability |
| Capability Ready | Capability passes readiness |
| Deployment Requested | Git change introduces deployment |
| Deployment Completed | Deployment finishes successfully |
| Deployment Failed | Deployment cannot complete |

### 8.3 Execution Model

| Property | Description |
|----------|-------------|
| Atomic | All-or-nothing at application level |
| Idempotent | Multiple triggers produce same result |
| Ordered | Respects capability dependencies |

### 8.4 Failure Model

| Category | Handling |
|----------|----------|
| Transient | Automatic retry with backoff |
| Persistent | Alert and manual intervention |
| Partial | Treated as failure, ArgoCD handles rollback |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 4. Components](./04-components.md) | [Table of Contents](./00-index.md#table-of-contents) | [6. Shared Infrastructure →](./06-shared-infrastructure.md) |

---

*End of Section 5 — RFC-PLATARCH-0001*
