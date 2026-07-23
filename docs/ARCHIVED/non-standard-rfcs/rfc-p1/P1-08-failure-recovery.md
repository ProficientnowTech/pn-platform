# RFC-P1-08 — Failure Semantics & Recovery

**Status:** Draft
**Audience:** Platform Engineers, Architects, Operations Teams

---

## 1. Introduction

This document defines how the orchestration system handles failures and recovers from them. It establishes the semantics of unresolved capabilities, explains partial failure handling, describes replay and rebuild mechanisms, and specifies requirements for deterministic recovery. These semantics ensure that the system is resilient to failures at all levels.

---

## 2. Unresolved Capabilities

### 2.1 Definition of Unresolved Capability

A capability is unresolved when it is required by one or more consumers but has not been provided by any provider. An unresolved capability represents a dependency that cannot be satisfied.

Unresolved capabilities may arise from:

**Provider Failure:** The resource that was supposed to provide the capability failed. The capability was never provided.

**Provider Absence:** No resource in the deployment provides the required capability. The dependency cannot be satisfied by any resource in the system.

**Provider Delay:** The provider has not yet completed. The capability will eventually be provided but is not yet available.

The distinction between these causes affects the response. Provider delay is normal operation; the consumer waits. Provider failure requires recovery. Provider absence is a configuration error requiring correction.

### 2.2 Detecting Unresolved Capabilities

The orchestrator must detect unresolved capabilities. Detection involves tracking:

**Required Capabilities:** For each resource, the capabilities it requires.

**Provided Capabilities:** For each resource, the capabilities it provides, and whether they have been provided.

**Matching:** For each required capability, which resource provides it.

An unresolved capability is detected when a required capability has no provider or when its provider has failed.

### 2.3 Consequences of Unresolved Capabilities

When a capability is unresolved, all resources that require it are blocked. A blocked resource cannot proceed until its dependencies are satisfied. If a dependency cannot be satisfied, the resource cannot proceed at all.

Blocking propagates through the dependency graph. If A requires capability X, and X is unresolved, A is blocked. If B requires capability Y from A, and A is blocked, B cannot receive Y. B is transitively blocked.

This propagation is correct behavior. A resource must not proceed without its dependencies. If a dependency is unresolved, all resources in the dependency chain must wait.

### 2.4 Unresolved vs. Failed

An unresolved capability is not the same as a failed resource. A capability may be unresolved because its provider has not yet run, or because its provider is in progress, or because its provider failed.

The orchestrator must distinguish these states:

**Pending:** The provider exists but has not started. The capability will be provided when the provider runs.

**In Progress:** The provider has started but not completed. The capability will be provided when the provider completes.

**Failed:** The provider attempted to provide the capability and failed. The capability will not be provided without intervention.

**Absent:** No provider exists for this capability. The deployment specification is incomplete.

Pending and in-progress states are normal. Failed and absent states require response.

---

## 3. Partial Failures

### 3.1 Definition of Partial Failure

A partial failure occurs when some resources in a deployment succeed while others fail. The deployment is neither complete (not all resources succeeded) nor entirely failed (some resources succeeded).

Partial failures are common in complex deployments. A deployment of 100 resources may have 90 succeed and 10 fail. The system must handle this state correctly.

### 3.2 The Partial Failure State

After a partial failure, the system is in an intermediate state:

**Completed Resources:** Some resources have deployed and are providing their capabilities.

**Failed Resources:** Some resources have attempted deployment and failed.

**Blocked Resources:** Some resources have not deployed because their dependencies on failed resources cannot be satisfied.

**Ready Resources:** Some resources could deploy (their dependencies are satisfied) but have not yet been initiated.

This state must be represented accurately. The orchestrator must know which resources are in which category. Operators must be able to observe this state.

### 3.3 Failure Isolation

A failure must affect only dependent resources. If resource A fails, resources that do not depend on A must be unaffected.

Failure isolation requires that:

**Independent Resources Continue:** Resources without dependencies on the failed resource must continue executing or waiting normally.

**Dependent Resources Block:** Resources with dependencies on the failed resource must block, unable to proceed.

**Transitive Dependents Block:** Resources that depend on blocked resources must also block.

Failure does not propagate beyond the dependency graph. If A fails, and B does not depend on A (directly or transitively), B is unaffected by A's failure.

### 3.4 No Global Abort

A failure does not abort the entire deployment. The deployment continues for all resources not affected by the failure.

This behavior maximizes progress. If 90 resources are independent of a failed resource, those 90 resources can complete successfully. Only the resources depending on the failure are blocked.

Global abort would sacrifice this progress. If any failure aborted everything, a single failure in a 100-resource deployment would prevent 99 successful deployments. This waste is unacceptable.

### 3.5 Partial Success Is Valid

A partially successful deployment is a valid end state. It is not an error state that must be resolved before the system is usable. The successful portion of the deployment provides its capabilities; the failed portion does not.

Operators may choose to:

**Accept Partial Success:** The successful portion is sufficient. The failed portion was not critical or can be addressed later.

**Retry Failed Resources:** Attempt to deploy the failed resources again, potentially after correcting the cause of failure.

**Rollback Successful Resources:** Remove the successful resources to return to the pre-deployment state.

These choices are operational decisions, not system mandates. The system supports all of them.

---

## 4. Replay and Rebuild

### 4.1 Replay for Recovery

Replay is the process of reprocessing events to recover state. When the orchestrator fails and restarts, it replays events to reconstruct its understanding of deployment progress.

Replay enables recovery without external state storage. The orchestrator does not need to persist its internal state to durable storage. It persists events. On restart, it replays events to rebuild state.

Replay must be deterministic. Replaying the same events must produce the same state. This determinism ensures that recovery produces correct results.

### 4.2 What Replay Recovers

Replay recovers the orchestrator's knowledge of:

**Resource States:** Which resources have been initiated, are in progress, have completed, or have failed.

**Capability Provision:** Which capabilities have been provided by which resources.

**Dependency Satisfaction:** Which resources have satisfied dependencies and are ready to proceed.

**Deployment Progress:** The overall progress of the deployment toward completion.

Replay does not recover external state. If a resource was deploying when the orchestrator failed, replay does not know whether that deployment completed. External systems must be queried to determine current state.

### 4.3 Rebuild for Correction

Rebuild is the process of reconstructing deployment state from external observation. Unlike replay (which reconstructs from events), rebuild queries external systems to determine actual state.

Rebuild is used when:

**Events Are Lost:** If events were lost, replay cannot recover the lost information. Rebuild queries external systems to determine what actually happened.

**Events Are Suspect:** If there is reason to doubt event accuracy, rebuild provides ground truth from external observation.

**External Changes Occurred:** If external systems changed while the orchestrator was down, replay would not capture those changes. Rebuild observes current state.

### 4.4 Replay and Rebuild Together

Recovery typically involves both replay and rebuild:

1. Replay events to recover the orchestrator's last known state.
2. Query external systems to determine actual current state.
3. Compare replayed state with observed state.
4. Reconcile discrepancies.

Discrepancies indicate that something happened that was not captured in events. Perhaps the orchestrator failed before recording an event. Perhaps an external system changed independently. Rebuild provides the truth; the orchestrator adjusts to match.

### 4.5 Rebuild Correctness

Rebuild must produce correct state. The orchestrator must accurately observe external systems and correctly interpret what it observes.

Rebuild correctness requires:

**Complete Observation:** All relevant external state must be observed. Missing observations produce incomplete state.

**Accurate Interpretation:** Observations must be correctly mapped to orchestrator state. A resource that appears healthy must be correctly identified as having provided its capabilities (or not).

**Consistent Snapshot:** Observations must represent a consistent point in time. If resource A is observed before resource B changes, the rebuild state must not reflect B's change as having occurred before A's observation.

---

## 5. Deterministic Recovery

### 5.1 Definition of Deterministic Recovery

Recovery is deterministic if the same failure scenario always produces the same recovered state and the same subsequent behavior. Given the same events, the same external state, and the same failure, the system must recover identically every time.

Deterministic recovery ensures predictability. Operators can reason about what will happen after a failure. Testing can verify recovery behavior. Debugging can reproduce recovery scenarios.

### 5.2 Requirements for Determinism

Deterministic recovery requires:

**Deterministic Replay:** Replaying events must produce identical state regardless of when or how often replay occurs.

**Deterministic Rebuild:** Querying external systems and interpreting results must produce identical state given identical external conditions.

**Deterministic Decision-Making:** Given identical recovered state, the orchestrator must make identical decisions about what to do next.

**No Hidden State:** Recovery must not depend on state that is not captured in events or observable in external systems.

### 5.3 Sources of Non-Determinism

Non-determinism can arise from:

**Timing Dependencies:** If recovery behavior depends on wall-clock time, different recovery times produce different behavior.

**Random Choices:** If the orchestrator makes random decisions (e.g., random tiebreaking), different recoveries produce different results.

**External Variability:** If external systems return different results at different times (beyond actual state changes), observation becomes non-deterministic.

**Unordered Operations:** If the orchestrator processes items in undefined order (e.g., iterating over a hash map), different runs may process items differently.

All sources of non-determinism must be eliminated or controlled. Timing must come from events, not clocks. Tiebreaking must be deterministic. External queries must return consistent results. Processing order must be defined.

### 5.4 Deterministic Ordering After Recovery

After recovery, the orchestrator must produce the same ordering decisions it would have produced without the failure. If resources A and B were both ready before the failure, and neither has completed, the orchestrator must handle them identically after recovery.

This requirement ensures that failure does not change semantics. A deployment that fails and recovers must produce the same result as a deployment that does not fail. The failure is a disruption, not a semantic change.

### 5.5 Recovery Idempotency

Recovery must be idempotent. Recovering multiple times from the same failure must produce the same result as recovering once. If recovery is interrupted and restarted, the second recovery must succeed correctly.

Idempotent recovery enables robustness. If recovery itself fails, it can be retried. There is no "recovery failed and now the system is in an unrecoverable state." Recovery can always be attempted again.

---

## 6. Recovery Procedures

### 6.1 Recovery from Orchestrator Failure

When the orchestrator fails and restarts:

1. Load the event log from durable storage.
2. Replay events to reconstruct last known state.
3. Query external systems to determine current actual state.
4. Compare reconstructed state with actual state.
5. Update internal state to match actual state.
6. Resume normal operation, making decisions based on current state.

The deployment continues from where it was. Completed resources remain completed. Failed resources remain failed. In-progress resources are re-evaluated based on their actual current state.

### 6.2 Recovery from Resource Failure

When a resource fails:

1. Record the failure event.
2. Mark the resource as failed.
3. Mark the resource's capabilities as not provided.
4. Evaluate all resources that depend on those capabilities.
5. Block resources with unsatisfied dependencies.
6. Continue executing resources without unsatisfied dependencies.

The deployment continues for unaffected resources. Affected resources wait for the failure to be resolved.

### 6.3 Recovery from External System Failure

When an external system fails (e.g., the cluster is unreachable):

1. Record the external failure.
2. Suspend operations that require the external system.
3. Continue operations that do not require the external system.
4. Periodically attempt to reconnect.
5. When connection is restored, rebuild state from external observation.
6. Resume suspended operations.

The orchestrator does not assume the worst. It suspends affected operations and waits for recovery. When the external system recovers, the orchestrator recovers with it.

### 6.4 Retry Semantics

Failed operations may be retried. Retry behavior must be:

**Bounded:** Retries must have a limit. Infinite retries would cause infinite loops on permanent failures.

**Delayed:** Retries must be delayed. Immediate retries on transient failures may fail repeatedly. Delay allows transient conditions to clear.

**Idempotent:** Retried operations must be safe to repeat. Retrying a non-idempotent operation could cause corruption.

Retry limits and delays are operational parameters. They affect how long recovery takes, not whether recovery succeeds. A failure that exceeds retry limits becomes a permanent failure requiring operator intervention.

---

## 7. Failure Semantics Summary

### 7.1 Principles

**Failures Are Local:** A failure affects only dependent resources.

**Progress Continues:** Unaffected resources continue executing.

**Recovery Is Deterministic:** The same failure produces the same recovery.

**Recovery Is Idempotent:** Recovery can be retried safely.

### 7.2 Guarantees

The system guarantees that:

- A failure will not corrupt state.
- A failure will not cause unrelated resources to fail.
- Recovery will restore correct operation.
- Recovery will not introduce non-determinism.

### 7.3 Non-Guarantees

The system does not guarantee that:

- Every failure will be recovered automatically. Permanent failures require operator intervention.
- Recovery will be instantaneous. Recovery takes time.
- Partial failures will eventually become complete successes. Partial success may be the final state.

---

*End of RFC-P1-08*
