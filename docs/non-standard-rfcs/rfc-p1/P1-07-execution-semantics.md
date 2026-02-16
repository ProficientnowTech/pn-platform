# RFC-P1-07 — Orchestration Execution Semantics

**Status:** Draft
**Audience:** Platform Engineers, Architects, Operations Teams

---

## 1. Introduction

This document defines how the orchestration system makes progress. It establishes that execution is asynchronous, explains how dependencies are resolved locally for each resource, specifies parallelism guarantees, and explicitly rejects phase-based and stack-based execution models. These semantics determine how deployments proceed from initiation to completion.

---

## 2. Asynchronous Execution

### 2.1 Definition of Asynchronous Execution

Asynchronous execution means that operations proceed independently without blocking on each other except where dependencies require synchronization. The orchestrator initiates operations and continues without waiting for their completion. Completion is signaled through events, not through synchronous return.

In synchronous execution, operation A completes, then operation B begins. The caller waits for A before starting B. The entire sequence blocks on each step.

In asynchronous execution, operations A, B, and C may all be in progress simultaneously. The orchestrator does not wait for A to complete before initiating B. Each operation proceeds independently. Completion events inform the orchestrator when operations finish.

### 2.2 Why Asynchronous Execution Is Required

Asynchronous execution is required for parallelism. If the orchestrator blocked on each operation, independent operations would execute sequentially. Resources without dependencies on each other would wait in line. This sequential execution wastes time and resources.

Asynchronous execution is required for responsiveness. A synchronous orchestrator is blocked while waiting for operations. It cannot observe new events, cannot respond to failures, cannot provide status. An asynchronous orchestrator remains responsive throughout execution.

Asynchronous execution is required for scalability. A synchronous orchestrator can manage one operation at a time. An asynchronous orchestrator can manage thousands of operations concurrently. Platform deployments involve many resources; asynchronous execution enables their concurrent management.

### 2.3 The Event-Driven Model

Asynchronous execution requires a mechanism for learning about completion. This mechanism is events. When an operation completes, an event is produced. The orchestrator observes the event and updates its understanding of system state.

The orchestrator does not poll for completion. Polling is periodic checking: "is A done yet? is A done yet? is A done yet?" Polling wastes resources and introduces latency (the time between completion and the next poll).

The orchestrator reacts to events. When A completes, an event is produced. The orchestrator observes the event immediately. There is no polling interval, no wasted queries, no latency beyond event propagation.

### 2.4 Operation Lifecycle

Each operation has a lifecycle:

**Initiated:** The orchestrator has started the operation. The operation is in progress.

**Completed:** The operation has finished successfully. An event signals completion.

**Failed:** The operation has finished unsuccessfully. An event signals failure.

The orchestrator tracks operations through this lifecycle. It knows which operations are in progress, which have completed, and which have failed. This tracking is maintained through events, not through synchronous status queries.

### 2.5 No Blocking Waits

The orchestrator must not block waiting for operation completion. Blocking defeats asynchronous execution. A blocked orchestrator cannot process other events, cannot initiate other operations, cannot respond to failures.

The orchestrator initiates operations and records that they are in progress. It then continues processing other events and initiating other operations. When completion events arrive, the orchestrator processes them. The orchestrator is always working, never waiting.

This constraint is absolute. There is no "brief blocking" or "blocking in special cases." The orchestrator is asynchronous or it is incorrect.

---

## 3. Local Dependency Resolution

### 3.1 Definition of Local Resolution

Local dependency resolution means that each resource's dependencies are evaluated independently. When considering whether resource A may proceed, the orchestrator examines only A's declared requirements and whether those requirements are satisfied. It does not consider the requirements of other resources or the global deployment plan.

Local resolution contrasts with global resolution. In global resolution, the orchestrator computes a complete ordering for all resources before execution begins. In local resolution, the orchestrator evaluates each resource's readiness at the moment the resource is considered.

### 3.2 How Local Resolution Works

For each resource, the orchestrator maintains:
- The set of capabilities the resource requires
- The current provision state of each required capability

When the orchestrator considers a resource, it checks: are all required capabilities currently provided? If yes, the resource may proceed. If no, the resource must wait.

This check is local. It examines only the resource's requirements and the current provision state. It does not examine other resources' requirements. It does not examine a pre-computed global plan.

### 3.3 Why Local Resolution Is Correct

Local resolution is correct because capabilities fully express dependencies. If resource A requires capabilities X and Y, then A may proceed if and only if X and Y are provided. The state of other resources is irrelevant to A's readiness.

Global plans encode the same information less directly. A global plan might say "A comes after B and C." This encodes the fact that A requires capabilities provided by B and C. But the plan is computed once, before execution. If B completes faster than expected, or C fails, the plan must be recomputed or ignored.

Local resolution adapts automatically. If B completes, the orchestrator immediately knows that B's capabilities are provided. Any resource requiring those capabilities becomes ready. No plan recomputation is needed. The evaluation uses current state, not predicted state.

### 3.4 Local Resolution and Parallelism

Local resolution enables maximum parallelism. Two resources execute in parallel if and only if neither depends on the other. This determination is made locally: A and B execute in parallel if A's requirements are satisfied and B's requirements are satisfied, regardless of any other consideration.

Global plans may under-parallelize. A plan that places A before B might do so for reasons unrelated to dependencies. Perhaps the planner decided A should go first. But if A and B are independent, forcing A before B wastes parallelism.

Local resolution does not over-parallelize or under-parallelize. It paralyzes exactly what can be parallelized: resources whose dependencies are satisfied.

### 3.5 Local Resolution and Ordering

Local resolution produces ordering as an emergent property. If A requires capability X and B provides capability X, then B must complete before A may proceed. This ordering emerges from the dependency relationship. It is not specified separately.

The orchestrator does not maintain an ordering. It does not say "B then A." It says "A requires X; X is not yet provided; A waits." When B provides X, the orchestrator says "A requires X; X is provided; A proceeds." The ordering emerges from dependency satisfaction, not from explicit sequencing.

---

## 4. Parallelism Guarantees

### 4.1 The Parallelism Principle

Resources execute in parallel if and only if they have no unsatisfied dependencies that would be affected by the other's execution. More precisely: resources A and B may execute in parallel if neither directly nor transitively depends on the other.

This principle is both a permission and a constraint. It permits parallelism where dependencies allow. It constrains parallelism where dependencies forbid.

### 4.2 Maximum Parallelism

The orchestrator must achieve maximum parallelism consistent with dependency satisfaction. If resources A, B, and C have no dependencies on each other, they must execute in parallel. The orchestrator must not serialize them arbitrarily.

Maximum parallelism is not optional. An orchestrator that unnecessarily serializes independent resources violates the execution model. It produces correct results more slowly than necessary. Slowness is a defect.

### 4.3 No Artificial Constraints

The orchestrator must not impose ordering constraints beyond those required by dependencies. If no dependency exists between A and B, no ordering must be imposed between A and B.

Artificial constraints reduce parallelism. They make deployments slower. They also obscure the true dependency structure: an operator observing the deployment might believe A depends on B when it does not.

The dependency graph is the complete specification of ordering constraints. Any ordering not derivable from the dependency graph is artificial and prohibited.

### 4.4 Parallelism Limits

The orchestrator may impose practical limits on parallelism. There may be resource constraints: only N operations can be in flight simultaneously. There may be rate limits: only M operations can be initiated per unit time.

These limits are operational constraints, not semantic constraints. They affect how fast the system converges, not what state it converges to. A deployment with a parallelism limit of 10 and a limit of 100 will reach the same final state; one will reach it faster.

Operational limits must not change ordering. If A and B are independent, and the parallelism limit allows only one operation, the orchestrator may execute A then B, or B then A. Both orderings are correct. But the orchestrator must not execute A then B because A depends on B; that dependency does not exist.

### 4.5 Parallelism and Correctness

Parallelism does not compromise correctness. Two resources executing in parallel are, by definition, resources without mutual dependencies. Their parallel execution cannot produce incorrect state because neither affects the other.

This statement assumes the dependency graph is complete and correct. If the dependency graph omits a dependency (A actually needs B, but this is not declared), parallel execution may fail. But this is a modeling error, not an execution error. The execution correctly implements the model; the model is incorrect.

Correctness requires correct modeling. Given correct modeling, parallel execution is correct execution.

---

## 5. Rejection of Phases and Stacks

### 5.1 What Phases Are

Phases divide deployment into sequential stages. Phase 1 completes before phase 2 begins. All resources in phase 1 execute (perhaps in parallel), then all resources in phase 2 execute. Phases impose a coarse-grained sequential structure.

Examples of phase-based models:
- "First deploy infrastructure, then deploy applications"
- "First deploy databases, then deploy services, then deploy frontends"
- "Phase 1: core services. Phase 2: dependent services. Phase 3: edge services."

### 5.2 What Stacks Are

Stacks organize resources into hierarchical layers. Lower stacks deploy before higher stacks. All resources in stack N complete before any resource in stack N+1 begins. Stacks impose a vertical sequential structure.

Examples of stack-based models:
- "Network stack, then storage stack, then compute stack"
- "Infrastructure stack, then platform stack, then application stack"
- "Layer 0 (bare metal), Layer 1 (virtualization), Layer 2 (orchestration), Layer 3 (workloads)"

### 5.3 Why Phases and Stacks Are Rejected

Phases and stacks are rejected because they impose artificial ordering constraints.

Consider two resources: A in phase 1, B in phase 2. The phase model requires A to complete before B begins. But what if A and B have no dependency? The phase model serializes them anyway. Parallelism is lost.

Consider two resources: X in stack 1, Y in stack 2. The stack model requires X to complete before Y begins. But what if X and Y have no dependency? The stack model serializes them anyway. Parallelism is lost.

Phases and stacks are imprecise. They group resources into buckets and serialize the buckets. But the correct serialization is at the dependency level, not the bucket level. A resource in phase 1 may have no dependencies; it could execute immediately. A resource in phase 2 may depend only on one resource in phase 1; it could execute as soon as that one resource completes, not when all of phase 1 completes.

### 5.4 Phases and Stacks as Modeling Failures

Phases and stacks attempt to express dependencies through grouping. Instead of declaring "B requires X from A," the operator puts A in phase 1 and B in phase 2. The dependency is implicit in the phase assignment.

This is a modeling failure. The dependency exists but is not declared. The system does not know B requires X from A. The system knows only that B is in phase 2. If A moves to phase 2, the implicit dependency is lost. If B moves to phase 1, B may execute before A.

The capability model requires explicit dependencies. Every requirement must be declared. Phases and stacks do not declare dependencies; they encode them implicitly. This implicit encoding violates the modeling requirements.

### 5.5 The Granularity Problem

Phases and stacks are coarse-grained. They operate on groups of resources, not on individual dependencies.

If phase 1 contains resources A, B, C, and phase 2 contains resources D, E, F, the model says: "D, E, F all depend on A, B, C all completing." But this is rarely true. Perhaps D depends on A only. Perhaps E depends on A and B. Perhaps F depends on C only. The phase model cannot express these distinctions.

The capability model is fine-grained. Each resource declares its specific requirements. D requires capability from A; D does not wait for B and C. E requires capabilities from A and B; E does not wait for C. F requires capability from C; F does not wait for A and B. Each resource waits only for what it actually needs.

### 5.6 No Phases, No Stacks

The orchestration system does not implement phases. The orchestration system does not implement stacks. Resources declare capabilities and requirements. The orchestrator resolves dependencies locally. Resources execute when their dependencies are satisfied.

This model is strictly more expressive than phases or stacks. Any phase-based or stack-based deployment can be expressed through capabilities. But capability-based deployments express the true dependency structure, enabling maximum parallelism.

Phases and stacks are prohibited because they are inferior. They lose information (true dependencies), they lose performance (unnecessary serialization), and they lose clarity (implicit vs. explicit dependencies).

---

## 6. Execution Model Summary

### 6.1 How Deployment Proceeds

A deployment proceeds as follows:

1. The orchestrator receives the deployment specification containing resources, capabilities, and requirements.

2. The orchestrator computes which resources have no unsatisfied requirements. These resources may proceed immediately.

3. The orchestrator initiates operations for ready resources. Initiation is asynchronous; the orchestrator does not wait.

4. As operations complete, events are produced. The orchestrator observes completion events.

5. When a resource completes and provides capabilities, the orchestrator re-evaluates waiting resources. Resources whose requirements are now satisfied become ready.

6. The orchestrator initiates operations for newly ready resources.

7. Steps 4-6 repeat until all resources are complete or the deployment has failed.

### 6.2 Key Properties

**Asynchronous:** Operations proceed without blocking.

**Event-Driven:** Completion is signaled through events.

**Locally Resolved:** Each resource's readiness is evaluated independently.

**Maximally Parallel:** Independent resources execute concurrently.

**Dependency-Ordered:** Dependent resources wait for dependencies.

**No Phases:** Grouping does not impose ordering.

**No Stacks:** Layering does not impose ordering.

### 6.3 What the Model Achieves

This execution model achieves correct, efficient deployment. Correctness comes from dependency enforcement: resources do not proceed until their dependencies are satisfied. Efficiency comes from parallelism: resources without mutual dependencies proceed concurrently.

The model achieves these properties without operator-specified ordering. The operator declares capabilities and requirements. The orchestrator derives ordering. The ordering is correct by construction and maximally parallel by design.

---

*End of RFC-P1-07*
