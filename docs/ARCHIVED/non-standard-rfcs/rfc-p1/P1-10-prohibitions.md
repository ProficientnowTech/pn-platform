# RFC-P1-10 — Explicit Prohibitions

**Status:** Draft
**Audience:** Platform Engineers, Architects, Operations Teams

---

## 1. Introduction

This document enumerates patterns that are explicitly forbidden within the orchestration system. Each prohibition exists to prevent regression to models that have been rejected for cause. For each forbidden pattern, this document explains why the pattern is forbidden and identifies the conceptual alternative within the orchestration model. This document does not propose solutions; it prevents known-bad approaches.

---

## 2. Forbidden Pattern: Shell Script Orchestration

### 2.1 Description

Shell script orchestration uses bash scripts or similar procedural code to coordinate deployments. Scripts execute commands in sequence, use conditionals to check status, and loop until conditions are met.

### 2.2 Why It Is Forbidden

**Implicit State:** Shell scripts maintain state in variables, files, or the operator's understanding. This state is not observable, not durable, and not recoverable after failure.

**Non-Idempotent Operations:** Shell scripts frequently perform operations that are not idempotent. Running a script twice may produce different results than running it once.

**No Dependency Model:** Shell scripts encode dependencies as execution order. The dependency is implicit in "A runs before B," not explicit as "B requires X from A."

**Failure Brittleness:** When a script fails partway, the system is in an undefined state. Recovery requires understanding what succeeded and what failed, which the script does not track.

**Human Dependency:** Shell scripts require a human to run them. Unattended operation, automatic recovery, and event-driven execution are not possible.

### 2.3 Conceptual Alternative

Dependencies are declared explicitly in the capability model. The orchestrator evaluates dependencies and releases work. Execution is event-driven, not script-driven. State is tracked in the orchestrator, not in script variables.

---

## 3. Forbidden Pattern: Hook-Based Coordination

### 3.1 Description

Hook-based coordination uses pre-sync, post-sync, pre-install, post-install, or similar hooks to inject procedural steps into declarative pipelines. Hooks run scripts or jobs at specific points in a sync or deployment lifecycle.

### 3.2 Why It Is Forbidden

**Hidden Dependencies:** Hooks encode dependencies that are not visible in the resource model. A pre-sync hook that waits for an external service implies a dependency that is nowhere declared.

**Position Sensitivity:** Hook behavior depends on when the hook runs. A pre-sync hook and a post-sync hook have different semantics based solely on position. This creates implicit meaning that is not self-documenting.

**Procedural Contamination:** Hooks inject procedural logic into declarative systems. The declarative model says "this is desired state." Hooks say "but first, do this." This contamination undermines declarative benefits.

**Reconciliation Interference:** Hooks run during reconciliation, coupling orchestration concerns to reconciliation operations. Reconciliation must be local and continuous; hooks make it dependent on external state.

**Testing Difficulty:** Hooks are difficult to test in isolation. They run in the context of a sync operation, requiring full reconciliation infrastructure to exercise.

### 3.3 Conceptual Alternative

Dependencies are declared explicitly, not encoded in hooks. The orchestrator determines when resources are ready based on capability provision. No procedural steps are injected into reconciliation. Reconciliation remains purely declarative.

---

## 4. Forbidden Pattern: Wait Jobs

### 4.1 Description

Wait jobs are Kubernetes Jobs or similar constructs that poll for a condition before completing. A wait job might poll a database endpoint, an HTTP health check, or a Kubernetes resource status, completing successfully when the condition is met or failing after a timeout.

### 4.2 Why It Is Forbidden

**Polling Waste:** Wait jobs poll repeatedly, consuming resources to ask the same question over and over. Event-driven notification is more efficient: the condition is reported once when it becomes true.

**Timeout Brittleness:** Wait jobs have timeouts. If the condition takes longer than expected, the job fails even though success was imminent. Timeouts are guesses about timing, not guarantees about correctness.

**Wrong Abstraction:** Wait jobs test for observable conditions (port open, endpoint responding), not for semantic readiness. A database with an open port may not have completed initialization. Wait jobs test the wrong thing.

**No State Contribution:** Wait jobs do not contribute to system state. They complete or fail, but they do not provide information to the orchestrator about what they observed. They are black boxes.

**Sequential Bottlenecks:** Wait jobs run sequentially within sync waves or phases. They cannot express "wait for A or B, whichever comes first." They impose unnecessary serialization.

### 4.3 Conceptual Alternative

Readiness is determined by semantic verification, not by polling. Resources signal when they are ready through events. The orchestrator receives these signals and updates its state. No polling occurs. No timeouts determine correctness.

---

## 5. Forbidden Pattern: Sync Wave Orchestration

### 5.1 Description

Sync wave orchestration uses ArgoCD sync waves to order resource application within a sync operation. Resources are assigned wave numbers; lower waves are applied before higher waves.

### 5.2 Why It Is Forbidden

**Application vs. Reconciliation:** Sync waves order manifest application to the API server. They do not order reconciliation. Resource A in wave 0 may not have reconciled before resource B in wave 1 is applied.

**Single-Application Scope:** Sync waves operate within a single Application. Platform deployments span multiple Applications. Sync waves cannot express cross-Application dependencies.

**No Semantic Awareness:** Sync waves do not understand what resources need from each other. They order by number, not by dependency. Wave 0 before wave 1 says nothing about what wave 1 needs from wave 0.

**False Ordering Confidence:** Sync waves create the appearance of ordered deployment without the substance. Operators believe B deployed after A completed; in reality, B's manifests were submitted after A's, but reconciliation may have overlapped or reversed.

**Coarse Granularity:** Sync waves group resources into numbered buckets. Resources in the same wave have no ordering. Resources in different waves have total ordering. This is too coarse for expressing real dependencies.

### 5.3 Conceptual Alternative

Dependencies are expressed through capabilities, not wave numbers. The orchestrator enforces ordering based on capability provision. Cross-Application dependencies are supported. Ordering reflects semantic requirements, not arbitrary numbering.

---

## 6. Forbidden Pattern: Phase-Based Deployment

### 6.1 Description

Phase-based deployment divides resources into sequential phases. All resources in phase N must complete before any resource in phase N+1 begins. Phases impose a coarse sequential structure on deployment.

### 6.2 Why It Is Forbidden

**Over-Serialization:** Phases serialize resources that may have no dependencies on each other. If phase 1 contains A and B, and phase 2 contains C and D, and D depends only on A, D must still wait for B. Parallelism is lost.

**Implicit Dependencies:** Placing resources in phases implies dependencies without declaring them. Why is X in phase 2? Because it "needs phase 1 to complete." But what specifically does X need?

**Rigid Structure:** Phases are static. Adding a resource requires deciding which phase it belongs to. Moving a resource between phases changes its dependencies implicitly.

**All-or-Nothing Synchronization:** All of phase N must complete before phase N+1 begins. A single slow resource in phase N delays everything in phase N+1, even resources that do not depend on the slow resource.

**Modeling Poverty:** Phases cannot express "C depends on A but not B." Phases can only express "phase 2 depends on phase 1." The model is impoverished.

### 6.3 Conceptual Alternative

Resources declare specific requirements, not phase membership. A resource waits only for what it needs, not for an entire phase. Parallelism is maximized. Dependencies are explicit.

---

## 7. Forbidden Pattern: Stack-Based Deployment

### 7.1 Description

Stack-based deployment organizes resources into hierarchical layers or stacks. Lower stacks deploy before higher stacks. Resources in stack N must complete before resources in stack N+1 begin.

### 7.2 Why It Is Forbidden

Stack-based deployment shares all the problems of phase-based deployment:

**Over-Serialization:** Resources in higher stacks wait for all of lower stacks, not just their actual dependencies.

**Implicit Dependencies:** Stack membership implies dependencies without declaring them.

**Rigid Structure:** Stack assignment is static and coarse-grained.

**All-or-Nothing Synchronization:** An entire stack must complete before the next begins.

Additionally, stacks introduce:

**Hierarchical Assumptions:** Stacks assume dependencies flow in one direction: lower to higher. Real dependencies may be more complex, with bidirectional or cross-cutting relationships.

**Layer Confusion:** The "right" layer for a resource may be ambiguous. Is a database in the infrastructure stack or the data stack? Is a service mesh in the network stack or the platform stack? These questions distract from actual dependencies.

### 7.3 Conceptual Alternative

Resources declare requirements regardless of conceptual layering. A resource that needs storage declares that need; it does not need to know what "layer" storage is in. The orchestrator resolves dependencies without layer concepts.

---

## 8. Forbidden Pattern: Application-to-Application Dependencies

### 8.1 Description

Application-to-application dependencies express that ArgoCD Application B depends on ArgoCD Application A. When A is synced (or healthy), B may be synced.

### 8.2 Why It Is Forbidden

**Wrong Abstraction:** Applications are organizational containers, not semantic units. B does not depend on A; B depends on capabilities provided by resources in A. The dependency is on capability, not on container.

**Sync ≠ Ready:** Application A being synced does not mean A is ready to be consumed. Sync means manifests were applied. Ready means resources achieved correctness. These are different states.

**Granularity Mismatch:** An Application may contain many resources. B may depend on only one resource in A. Application-level dependency forces B to wait for all of A, not just the relevant resource.

**No Capability Tracking:** Application dependencies do not specify what B needs from A. When A is synced, what capability does that represent? The dependency is syntactic, not semantic.

**Fragile to Reorganization:** If resources move between Applications, application dependencies must be updated. Capability dependencies are unaffected by organizational changes.

### 8.3 Conceptual Alternative

Dependencies are declared at the capability level. Resources require capabilities; other resources provide capabilities. Applications are irrelevant to dependency evaluation. Reorganizing resources between Applications does not affect dependencies.

---

## 9. Forbidden Pattern: Polling for Readiness

### 9.1 Description

Polling for readiness involves periodically querying a system to determine if it is ready. A component polls a database, an API, or a Kubernetes resource at intervals until the query returns a ready response.

### 9.2 Why It Is Forbidden

**Resource Waste:** Polling consumes resources with every query. Frequent polling wastes more resources. Infrequent polling increases latency. There is no good polling interval.

**Latency Introduction:** Between polls, readiness may be achieved but not observed. Average latency is half the polling interval. This delay slows deployment unnecessarily.

**Scalability Problems:** Polling scales poorly. N components polling M targets creates N×M queries per interval. As systems grow, polling load grows quadratically.

**Race Conditions:** Polling introduces race windows. Readiness may be achieved and then lost between polls. The polling component may act on stale information.

**No Event Correlation:** Polling produces point-in-time snapshots. It cannot correlate events or understand sequences. The component knows the current state, not how the state was reached.

### 9.3 Conceptual Alternative

Readiness is communicated through events. When a resource becomes ready, it emits an event. The orchestrator receives the event immediately. No polling occurs. No latency is introduced. No resources are wasted on repeated queries.

---

## 10. Forbidden Pattern: Health-Based Dependency Satisfaction

### 10.1 Description

Health-based dependency satisfaction treats a resource as ready when it is healthy. If Kubernetes reports a pod as healthy (passing liveness probes), dependencies on that pod are considered satisfied.

### 10.2 Why It Is Forbidden

**Health ≠ Correctness:** Health means the workload is alive. Correctness means the workload is semantically ready. These are different properties. A healthy database pod may not have initialized its schema.

**Wrong Metric:** Health is a survival metric for pod lifecycle management. It exists so Kubernetes can restart crashed pods. It does not exist for dependency evaluation.

**False Confidence:** Using health for dependency satisfaction creates false confidence. Dependencies appear satisfied because pods are healthy. Dependents fail because pods are not correct.

**Unpredictable Timing:** Health probes pass at unpredictable times during startup. A pod may become healthy before, during, or after initialization completes. Health timing does not correlate with readiness timing.

**Insufficient Granularity:** Health is per-pod. Capabilities may be provided by higher-level abstractions (StatefulSets, Services, operators). Pod health does not capture these abstractions.

### 10.3 Conceptual Alternative

Dependencies are satisfied by capability provision, not by health status. A resource provides capabilities when it has achieved correctness, regardless of when it became healthy. The orchestrator tracks capability provision explicitly.

---

## 11. Forbidden Pattern: Time-Based Waiting

### 11.1 Description

Time-based waiting assumes that if a resource has been deploying for N seconds, it must be ready. A deployment waits for a fixed duration, then proceeds assuming dependencies are satisfied.

### 11.2 Why It Is Forbidden

**No Causal Relationship:** Time does not cause readiness. A resource is ready when it completes initialization, not when a timer expires. The timer is unrelated to actual readiness.

**Wrong in Both Directions:** If the timer is too short, deployment proceeds before readiness. If the timer is too long, deployment is delayed unnecessarily. There is no "correct" timer value.

**Environmental Sensitivity:** Resource initialization time varies by environment. A timer that works in development may fail in production. Timers encode environmental assumptions that may not hold.

**Masked Failures:** If a resource fails during the wait period, the timer still expires. The deployment proceeds believing the resource is ready when it has actually failed. Failures are masked.

**Non-Determinism:** Time-based waits introduce non-determinism. Depending on system load, network conditions, and resource availability, the same deployment may succeed or fail. Deployments become flaky.

### 11.3 Conceptual Alternative

Readiness is determined by semantic verification, not by elapsed time. A resource signals readiness when it is ready, regardless of how long initialization took. The orchestrator responds to readiness signals, not to timers.

---

## 12. Forbidden Pattern: Manual Intervention Points

### 12.1 Description

Manual intervention points are places where deployment pauses for human approval or action. A deployment might pause after phase 1 for an operator to verify results before proceeding to phase 2.

### 12.2 Why It Is Forbidden

**Zero Human Intervention Violation:** The orchestration system requires zero human intervention from initiation to completion. Manual intervention points violate this requirement directly.

**Bottleneck Creation:** Humans are slow. A deployment waiting for human approval may wait hours or days. The human becomes a bottleneck.

**Inconsistency Introduction:** Human decisions are inconsistent. Different operators may make different decisions at intervention points. Deployments become non-deterministic based on who is operating.

**Availability Dependency:** Manual intervention requires human availability. Deployments cannot proceed during off-hours, vacations, or emergencies unless humans are available.

**Error Opportunity:** Manual intervention is an opportunity for human error. Operators may approve when they meant to reject, or vice versa. Manual steps increase error surface.

### 12.3 Conceptual Alternative

All decisions are made by the orchestrator based on declared dependencies and observed state. No human approval is required during deployment. Humans define the deployment specification; the orchestrator executes it autonomously.

---

## 13. Forbidden Pattern: Implicit Dependency Inference

### 13.1 Description

Implicit dependency inference attempts to determine dependencies by observing behavior rather than explicit declaration. The system might infer that B depends on A because B fails when A is unavailable, or because B's configuration references A.

### 13.2 Why It Is Forbidden

**Observability Limitation:** Inference can only discover dependencies that manifest observably. A dependency that causes silent incorrect behavior (not failure) will not be inferred.

**False Positives:** Inference may identify spurious dependencies. B might fail when A is unavailable for reasons unrelated to an actual dependency. Correlation is not causation.

**False Negatives:** Inference may miss real dependencies. If B has been deployed after A in all observed cases, the dependency might not manifest. But deploying B before A would fail.

**Late Discovery:** Inference discovers dependencies at runtime. By then, the deployment may have proceeded incorrectly. Dependencies must be known before deployment, not discovered during it.

**Incomplete Model:** Inferred dependencies are inherently incomplete. There is no guarantee that all dependencies have been discovered. Explicit declaration guarantees completeness (the declaration is the complete set).

### 13.3 Conceptual Alternative

All dependencies are explicitly declared. The orchestrator does not infer dependencies. If a dependency is not declared, the orchestrator does not know about it. This forces explicit modeling and produces a complete, known dependency graph.

---

## 14. Summary of Prohibitions

| Forbidden Pattern | Primary Violation | Alternative Concept |
|-------------------|-------------------|---------------------|
| Shell Script Orchestration | Implicit state, non-idempotent | Explicit capability model |
| Hook-Based Coordination | Hidden dependencies, procedural contamination | Explicit dependencies |
| Wait Jobs | Polling, wrong abstraction | Event-driven readiness |
| Sync Wave Orchestration | No semantic awareness, single-app scope | Capability-based ordering |
| Phase-Based Deployment | Over-serialization, implicit dependencies | Fine-grained dependencies |
| Stack-Based Deployment | Hierarchical assumptions, rigid structure | Requirement-based dependencies |
| Application-to-Application Dependencies | Wrong abstraction, sync ≠ ready | Capability provision |
| Polling for Readiness | Resource waste, latency | Event-driven notification |
| Health-Based Dependency Satisfaction | Health ≠ correctness | Semantic readiness |
| Time-Based Waiting | No causal relationship | Readiness signals |
| Manual Intervention Points | Zero human intervention violation | Autonomous orchestration |
| Implicit Dependency Inference | Incomplete, late discovery | Explicit declaration |

---

## 15. Enforcement

### 15.1 Design Review

All design proposals must be reviewed against this prohibition list. If a proposal incorporates a forbidden pattern, it must be rejected or revised.

### 15.2 Implementation Review

All implementation changes must be reviewed against this prohibition list. If an implementation introduces a forbidden pattern, it must be rejected or revised.

### 15.3 Regression Prevention

This document exists to prevent regression. The patterns listed here represent past approaches that have been evaluated and rejected. Reintroducing them would be regression to a known-inferior state.

When faced with a problem, the answer is never a forbidden pattern. The forbidden patterns are forbidden because they do not solve problems correctly; they create new problems or mask existing ones.

---

*End of RFC-P1-10*
