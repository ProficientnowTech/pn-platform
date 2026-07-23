# RFC-P1-05 — Readiness & Correctness Semantics

**Status:** Draft
**Audience:** Platform Engineers, Architects, Operations Teams

---

## 1. Introduction

This document defines the semantics of health, readiness, and correctness within the orchestration system. It establishes precise definitions for each term, explains why Kubernetes-native readiness is insufficient for orchestration purposes, and defines what it means for a resource to be "safe to consume." These definitions form the semantic foundation for capability provision.

---

## 2. Health, Readiness, and Correctness

### 2.1 Health: The Survival Property

Health indicates that a workload is alive. A healthy workload has not crashed, has not been terminated, and continues to execute. Health is a survival property: it answers the question "is this thing still running?"

Health is necessary but not sufficient. A workload that is not healthy cannot be correct. But a workload that is healthy may still be incorrect. Health is the floor, not the ceiling.

Health is observable through liveness. Kubernetes liveness probes test health. A workload that fails its liveness probe is restarted. The liveness probe exists to detect and recover from workloads that have stopped functioning at the most basic level.

Health says nothing about function. A healthy database pod is a pod that has not crashed. The pod may be healthy while the database process inside it is still initializing. The pod may be healthy while the database has no schema. The pod may be healthy while the database is in a completely unusable state. Health and function are independent properties.

### 2.2 Readiness: The Traffic Property

Readiness indicates that a workload is prepared to receive traffic. A ready workload has passed its readiness probe and is included in service load balancing. Readiness is a traffic property: it answers the question "should traffic be sent to this thing?"

Readiness is a Kubernetes construct with a specific purpose. Kubernetes uses readiness to determine service endpoint membership. A pod that is ready receives traffic through Services. A pod that is not ready does not receive traffic. This is the full extent of what readiness means in Kubernetes.

Readiness does not mean correct. A workload may be ready to receive traffic without being correct. A database may pass its readiness probe (accepting TCP connections) while its schema is uninitialized. An application may pass its readiness probe (responding to /health) while its dependencies are unavailable. Readiness probes test what they test; they do not test correctness.

Readiness is scoped to individual workloads. Kubernetes readiness applies to pods. It does not apply to logical services, to applications, or to capabilities. A pod is ready. A multi-pod deployment is not "ready" in any Kubernetes-defined sense; it is merely a collection of pods that are individually ready or not.

### 2.3 Correctness: The Semantic Property

Correctness indicates that a resource has achieved the state necessary to fulfill its purpose. A correct resource provides what it is supposed to provide. Correctness is a semantic property: it answers the question "can this thing do what it is supposed to do?"

Correctness is domain-specific. What makes a database correct is different from what makes a message queue correct, which is different from what makes a service mesh correct. Each resource type has its own correctness criteria based on its function.

Correctness implies capability provision. When a resource is correct, it can provide its capabilities. The connection between correctness and capability is direct: correctness is the state in which capabilities become available.

Correctness is not a Kubernetes concept. Kubernetes does not define correctness. Kubernetes does not measure correctness. Kubernetes does not report correctness. Correctness exists at a higher level of abstraction than Kubernetes provides.

### 2.4 The Hierarchy of Properties

The three properties form a hierarchy:

**Health is foundational.** Without health, nothing else matters. A crashed workload cannot be ready or correct.

**Readiness builds on health.** A workload must be healthy to be ready. But health does not imply readiness; a healthy workload may fail its readiness probe.

**Correctness builds on readiness.** A workload must typically be ready to be correct. But readiness does not imply correctness; a ready workload may be semantically incomplete.

This hierarchy means that testing for correctness implicitly tests for health and readiness. A correct workload is necessarily healthy (or it would not be running) and typically ready (or it could not serve its function). But testing for health or readiness does not test for correctness.

### 2.5 The Observability Gap

Health is observable through Kubernetes liveness probes. Readiness is observable through Kubernetes readiness probes. Correctness is not observable through any Kubernetes-native mechanism.

This gap is fundamental. Kubernetes is a container orchestration platform. It manages workload lifecycles. It does not understand workload semantics. A database and a web server are both pods to Kubernetes; it does not know that one stores data and one serves HTTP.

Because Kubernetes cannot observe correctness, systems that rely only on Kubernetes signals cannot determine correctness. They can determine health. They can determine readiness. They cannot determine whether a resource is semantically ready to fulfill its purpose.

---

## 3. Why Kubernetes Readiness Is Insufficient

### 3.1 Readiness Probes Test the Wrong Thing

Kubernetes readiness probes test whether a pod is ready to receive traffic. This is not the same as testing whether a pod is ready to be depended upon by other resources.

A database pod's readiness probe typically tests whether the database process is accepting connections. This tells Kubernetes that the pod can be included in Service endpoints. It does not tell the orchestrator that the database has completed initialization.

The readiness probe is designed for load balancer integration. It serves that purpose well. But orchestration dependencies are not load balancer decisions. They require different information.

### 3.2 Readiness Is Pod-Scoped

Kubernetes readiness applies to individual pods. An orchestration dependency typically depends on a logical resource, not on an individual pod.

A database may be deployed as a StatefulSet with three replicas. Each pod has its own readiness state. What does it mean for "the database" to be ready? All pods ready? A quorum ready? The primary ready? Kubernetes does not answer this question because Kubernetes does not think in terms of logical resources.

Orchestration dependencies require resource-level readiness, not pod-level readiness. Kubernetes does not provide resource-level readiness. A system that uses Kubernetes readiness for orchestration must map pod readiness to resource readiness, and this mapping is not provided by Kubernetes.

### 3.3 Readiness Does Not Capture Semantic State

Kubernetes readiness probes test observable conditions: TCP port open, HTTP endpoint responding, command exiting successfully. These conditions are proxies for semantic state, not semantic state itself.

A database with an open port and responding health endpoint may still be:
- Initializing its storage engine
- Running schema migrations
- Establishing replication
- Warming its cache

All of these states may pass readiness probes while the database is not semantically ready to serve its purpose. The readiness probe cannot distinguish between "accepting connections" and "fully initialized" because it tests observables, not semantics.

### 3.4 Readiness Is Designed for Steady State

Kubernetes readiness probes are designed for steady-state operation. They determine ongoing traffic routing. A pod that becomes unready stops receiving traffic. A pod that becomes ready again resumes receiving traffic.

Orchestration dependencies are not steady-state. They are transitional. The question is not "should this pod receive traffic right now?" but "has this resource completed its initialization so that dependents may proceed?" These are different questions with different answers.

A pod that flaps between ready and unready during initialization is problematic for orchestration. Kubernetes may include and exclude it from endpoints repeatedly. The orchestrator needs to know when initialization is complete, not whether the pod is momentarily passing its probe.

### 3.5 Readiness Cannot Express Capability Provision

Kubernetes readiness is binary: ready or not ready. Capability provision is potentially multiple: a resource may provide several capabilities, each with its own criteria.

A database may provide:
- Basic connectivity (for health checks)
- Schema availability (for applications)
- Replication (for high availability)
- Backup integration (for disaster recovery)

These are distinct capabilities with distinct readiness criteria. Kubernetes readiness cannot express "ready for connectivity but not ready for applications." It provides a single bit of information where multiple bits are required.

---

## 4. Definition of Safe to Consume

### 4.1 The Safety Requirement

A resource is safe to consume when consumers may proceed to deploy without risk of failure due to dependency unavailability. Safety is a guarantee: if a resource is safe to consume, consumers that depend on it will find their dependencies satisfied.

Safety is stronger than readiness. A resource may be ready (accepting traffic) without being safe to consume (guaranteed to satisfy consumer dependencies). Safety requires that the resource will continue to satisfy dependencies, not merely that it is currently operational.

### 4.2 Components of Safety

A resource is safe to consume when all of the following hold:

**Initialization is complete.** The resource has finished all startup procedures. It is not in a transitional state. It has achieved its operational configuration.

**Required state exists.** Any state that consumers depend on has been created. For a database, this means schemas exist. For a certificate authority, this means certificates are issued. For a message queue, this means topics are created.

**The resource is stable.** The resource is not expected to restart, reconfigure, or otherwise change state in ways that would invalidate consumer assumptions. Stability does not mean immutability; it means predictability.

**Dependencies are satisfied.** If the resource itself has dependencies, those dependencies are also safe to consume. Safety is transitive: a resource cannot be safe if its own dependencies are unsafe.

### 4.3 Safety as Capability Provision

When a resource is safe to consume, it provides its capabilities. The terms are equivalent from the orchestrator's perspective: a resource provides a capability if and only if that capability is safe to consume.

This equivalence connects safety to the capability model. Consumers require capabilities. Providers provide capabilities by becoming safe to consume. The orchestrator gates consumer execution on provider safety.

### 4.4 Safety Is Not Permanent

Safety is a point-in-time property. A resource that is safe to consume at time T may become unsafe at time T+1 if it fails, restarts, or reconfigures.

For orchestration purposes, safety must hold for long enough that consumers can initialize. Once consumers have initialized and established their connections, the dependency relationship becomes operational rather than orchestrational. Runtime failures are handled by runtime mechanisms, not by the orchestrator.

The orchestrator is concerned with initial safety: is the resource safe to consume during the deployment window? Ongoing safety during steady-state operation is outside orchestration scope.

### 4.5 Determining Safety

Safety cannot be determined by observing Kubernetes primitives alone. Kubernetes reports health and readiness, not safety. Determining safety requires domain-specific knowledge.

For each resource type, the criteria for safety must be defined. These criteria describe what it means for that resource type to have completed initialization, to have created required state, and to be stable. The criteria are resource-specific because safety is semantic, not syntactic.

The orchestration system must have a mechanism for determining safety based on these criteria. This mechanism must go beyond Kubernetes readiness probes to capture semantic state. The specifics of this mechanism are outside the scope of this document; what matters here is that such a mechanism must exist and must test for safety, not merely for readiness.

### 4.6 Safety Signals

When a resource achieves safety, this fact must be communicated to the orchestrator. The orchestrator cannot observe safety directly; it must be informed.

A safety signal is an explicit declaration that a resource is safe to consume. The signal must be:

**Explicit:** The signal must be an affirmative declaration, not an inference from other states.

**Reliable:** The signal must accurately reflect safety. A false safety signal causes consumers to proceed when their dependencies are not satisfied.

**Timely:** The signal must be produced when safety is achieved, not before (premature) or significantly after (delayed).

The mechanism for producing and consuming safety signals is outside the scope of this document. What matters is that safety must be signaled explicitly; it cannot be assumed from readiness or inferred from timing.

---

## 5. Correctness in Context

### 5.1 Correctness Relative to Capability

Correctness is always relative to a capability. A resource is not correct in the abstract; it is correct with respect to a specific capability it provides.

A database may be correct with respect to "basic-storage" (it can store and retrieve data) but not correct with respect to "replicated-storage" (replication is not yet established). Correctness is per-capability, not per-resource.

This granularity enables partial dependency satisfaction. A consumer that requires only basic-storage may proceed as soon as the database achieves that correctness. A consumer that requires replicated-storage must wait longer. Different consumers have different requirements and thus different thresholds for provider correctness.

### 5.2 Correctness Is Binary

For any given capability, correctness is binary. The capability is either provided or it is not. There is no partial correctness, no percentage correct, no "almost ready."

This binary nature simplifies orchestration. The orchestrator does not need to evaluate degrees of correctness. It needs only to evaluate presence or absence. Either the capability is provided and consumers may proceed, or it is not provided and consumers must wait.

### 5.3 Correctness and Failure

A resource that fails after achieving correctness may lose that correctness. If a database crashes, it is no longer correct with respect to its capabilities. When it recovers, it must re-achieve correctness.

For orchestration purposes, correctness loss after consumers have started is a runtime concern, not an orchestration concern. The orchestrator ensures that consumers do not start until providers are correct. What happens after consumers start is outside orchestration scope.

However, correctness loss during orchestration (before consumers have started) is an orchestration concern. If a provider achieves correctness, signals safety, and then fails before consumers start, the orchestrator must handle this situation. The specifics of failure handling are addressed in a separate document.

---

## 6. Summary

### 6.1 The Three Properties

**Health** indicates survival. Kubernetes liveness probes measure health.

**Readiness** indicates traffic acceptance. Kubernetes readiness probes measure readiness.

**Correctness** indicates semantic completion. No Kubernetes-native mechanism measures correctness.

### 6.2 The Key Insight

Kubernetes readiness is insufficient for orchestration because orchestration requires correctness, not readiness. A ready resource may be semantically incomplete. A correct resource is semantically complete and safe to consume.

### 6.3 The Operational Implication

The orchestration system must define and evaluate correctness independent of Kubernetes readiness. It must receive explicit safety signals indicating that resources are safe to consume. It must not rely on readiness probes as proxies for correctness.

---

*End of RFC-P1-05*
