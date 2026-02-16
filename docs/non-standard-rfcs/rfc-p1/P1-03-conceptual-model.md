# RFC-P1-03 — Conceptual Model

**Status:** Draft
**Audience:** Platform Engineers, Architects, Operations Teams

---

## 1. Introduction

This document establishes the conceptual model for platform orchestration. It defines the fundamental distinctions that underpin the system's design and explains why certain responsibilities must be separated. This model provides the mental framework for understanding all subsequent technical decisions.

---

## 2. Reconciliation vs. Orchestration

### 2.1 Definition of Reconciliation

Reconciliation is the process of making actual state match desired state for a single resource. A reconciler observes the current state of a resource, compares it to the desired state, and takes actions to eliminate the difference.

Reconciliation is reactive. The reconciler responds to discrepancies. It does not initiate change; it responds to change. When desired state changes, the reconciler detects the change and acts. When actual state drifts, the reconciler detects the drift and corrects it.

Reconciliation is continuous. A reconciler does not complete. It operates in a loop: observe, compare, act, repeat. The loop runs indefinitely, ensuring that actual state continuously converges toward desired state.

Reconciliation is local. A reconciler is concerned with a single resource or a single type of resource. It does not consider relationships between resources. It does not consider ordering. It does not consider dependencies. The reconciler's scope is the resource it manages.

### 2.2 Definition of Orchestration

Orchestration is the process of coordinating multiple reconciliations to achieve a system-wide outcome. An orchestrator determines which reconciliations may proceed, which must wait, and in what order work is released.

Orchestration is proactive. The orchestrator initiates work. It decides when a resource is ready to be reconciled based on the state of other resources. The orchestrator does not wait for discrepancies; it creates them deliberately by releasing desired state.

Orchestration is episodic. An orchestration has a beginning and an end. It starts when a deployment is initiated and ends when all resources have converged (or the deployment has failed). Between deployments, the orchestrator is idle.

Orchestration is global. The orchestrator considers all resources in a deployment. It understands relationships. It enforces ordering. It respects dependencies. The orchestrator's scope is the entire deployment.

### 2.3 The Distinction Is Fundamental

Reconciliation and orchestration are not variations of the same process. They are fundamentally different processes with different concerns, different lifecycles, and different scopes.

A system that conflates reconciliation and orchestration cannot correctly separate concerns. It will either impose orchestration constraints on reconciliation (making reconciliation dependent on external coordination) or impose reconciliation constraints on orchestration (making orchestration continuous when it must be episodic).

The system must maintain this distinction rigorously. Reconciliation must remain local and continuous. Orchestration must remain global and episodic. Neither process must assume responsibilities belonging to the other.

---

## 3. Why Orchestration Is External to ArgoCD

### 3.1 ArgoCD Is a Reconciler

ArgoCD implements the reconciliation pattern. It observes desired state (Git repositories), compares it to actual state (Kubernetes clusters), and takes actions to eliminate discrepancies. ArgoCD operates continuously, synchronizing cluster state with repository state.

ArgoCD's scope is the individual Application resource. Each Application represents a collection of Kubernetes resources whose desired state is defined in Git. ArgoCD reconciles each Application independently.

ArgoCD is not an orchestrator. ArgoCD does not coordinate between Applications. ArgoCD does not enforce ordering between Applications. ArgoCD does not understand dependencies between Applications. These are orchestration concerns, and ArgoCD does not address them.

### 3.2 Sync Waves Are Not Orchestration

ArgoCD provides sync waves as a mechanism for ordering resource application within a single Application. Sync waves order the submission of manifests to the Kubernetes API server. They do not order reconciliation. They do not verify readiness. They do not understand dependencies.

Sync waves operate at the wrong level of abstraction. They order API submissions, not state transitions. A resource in wave 0 is submitted before a resource in wave 1, but the wave 0 resource may not have reconciled before the wave 1 resource is submitted. Sync waves provide ordering without providing coordination.

Sync waves also operate at the wrong scope. They apply within an Application, not across Applications. Platform deployments involve multiple Applications with dependencies between them. Sync waves cannot express or enforce these cross-Application dependencies.

### 3.3 Hooks Are Not Orchestration

ArgoCD provides hooks as a mechanism for executing actions at specific points in the sync lifecycle. Hooks can run before sync, after sync, or on failure. Hooks are procedural insertions into the reconciliation process.

Hooks conflate reconciliation with orchestration. A pre-sync hook that waits for an external dependency is performing orchestration work within the reconciliation process. This conflation violates the fundamental distinction between the two processes.

Hooks also create hidden dependencies. The existence of a hook implies a dependency, but that dependency is not declared in any model. The dependency is encoded in the hook's implementation, not in the system's understanding of relationships.

### 3.4 The Necessity of External Orchestration

Because ArgoCD is a reconciler and not an orchestrator, orchestration must occur outside ArgoCD. An external system must determine when ArgoCD Applications are ready to sync. An external system must understand dependencies between Applications. An external system must enforce ordering based on those dependencies.

This external system is the orchestrator. The orchestrator does not replace ArgoCD. The orchestrator uses ArgoCD. ArgoCD reconciles individual Applications; the orchestrator coordinates which Applications are reconciled when.

The relationship is hierarchical. The orchestrator operates at a higher level of abstraction than ArgoCD. The orchestrator makes decisions about coordination; ArgoCD executes those decisions through reconciliation. Each system does what it is designed to do.

### 3.5 ArgoCD as an Execution Engine

Within this model, ArgoCD serves as an execution engine. The orchestrator determines that an Application is ready to sync. The orchestrator triggers the sync. ArgoCD performs the sync. ArgoCD reports the result. The orchestrator observes the result and makes further decisions.

ArgoCD does not need to understand orchestration. ArgoCD receives sync commands and executes them. The intelligence about when to sync, and in what order, resides in the orchestrator. ArgoCD provides the mechanism; the orchestrator provides the policy.

This separation preserves ArgoCD's design. ArgoCD remains a reconciler. It continues to do what reconcilers do. The orchestration concerns that ArgoCD cannot address are addressed by a system designed for orchestration.

---

## 4. System Roles at a Conceptual Level

### 4.1 The Orchestrator

The orchestrator is responsible for coordination. It maintains the dependency graph. It determines which resources have satisfied dependencies. It releases work to the reconciler. It observes outcomes and updates its understanding of system state.

The orchestrator does not apply manifests. It does not interact with Kubernetes directly. It does not perform reconciliation. The orchestrator decides; other systems execute.

The orchestrator is the authority on readiness. It determines when a resource is ready to be consumed by other resources. This determination is based on explicit signals, not on observation of Kubernetes state. The orchestrator knows what readiness means for each resource type.

### 4.2 The Reconciler

The reconciler is responsible for execution. It receives work from the orchestrator. It applies desired state to actual state. It reports outcomes. The reconciler in this system is ArgoCD.

The reconciler does not decide when to work. It does not evaluate dependencies. It does not coordinate with other reconcilers. The reconciler executes what it is given.

The reconciler is the authority on sync status. It knows whether an Application is synced, out-of-sync, progressing, or failed. It reports this status. The orchestrator consumes this status as input to its decisions.

### 4.3 The Readiness Verifier

The readiness verifier is responsible for determining semantic correctness. When a reconciler reports that an Application is synced, the readiness verifier determines whether that Application is actually ready to be consumed.

The readiness verifier understands domain-specific correctness. It knows that a database is ready when its schema is initialized. It knows that a certificate authority is ready when its root certificate is issued. It knows what "ready" means for each resource type.

The readiness verifier does not initiate work. It observes and reports. Its reports feed into the orchestrator's decision-making.

### 4.4 The Dependency Graph

The dependency graph is not a component but a data structure. It represents the declared dependencies between resources. The orchestrator uses the dependency graph to determine ordering. The dependency graph is static; it is computed from declarations before execution begins.

The dependency graph must be complete. It must contain all resources and all dependencies. The orchestrator must not discover dependencies during execution that were not in the graph before execution.

### 4.5 Role Boundaries

Each role has clear boundaries. The orchestrator does not reconcile. The reconciler does not orchestrate. The readiness verifier does not decide ordering. Each role performs its function and no other.

These boundaries are not arbitrary. They derive from the fundamental distinction between reconciliation and orchestration. They ensure that each component can be understood, tested, and operated independently. They prevent the conflation of concerns that makes systems difficult to reason about.

Violations of role boundaries are architectural defects. A reconciler that performs orchestration is incorrectly designed. An orchestrator that performs reconciliation is incorrectly designed. The boundaries must be maintained.

---

## 5. The Mental Model

### 5.1 Summary of the Model

The system consists of an orchestrator that coordinates, a reconciler that executes, and a readiness verifier that validates. The orchestrator consults a dependency graph to determine what work may proceed. The reconciler (ArgoCD) performs the work. The readiness verifier confirms that work is complete. The orchestrator observes the confirmation and releases further work.

### 5.2 What the Model Enables

This model enables separation of concerns. Orchestration logic is contained in the orchestrator. Reconciliation logic is contained in ArgoCD. Readiness logic is contained in the readiness verifier. Each concern is addressed by a component designed for that concern.

This model enables independent evolution. ArgoCD can be upgraded without changing orchestration logic. Orchestration logic can be modified without changing ArgoCD. Readiness definitions can be updated without changing either.

This model enables reasoning. Because concerns are separated, each component can be understood in isolation. The orchestrator's behavior depends only on the dependency graph and readiness signals. ArgoCD's behavior depends only on Git state and cluster state. The readiness verifier's behavior depends only on resource state and readiness definitions.

### 5.3 What the Model Requires

This model requires explicit dependency declaration. The orchestrator cannot coordinate what it does not know about. Dependencies must be declared, not inferred.

This model requires explicit readiness signals. The orchestrator cannot proceed on implicit readiness. Resources must signal when they are ready, and the meaning of "ready" must be defined.

This model requires disciplined role adherence. Each component must stay within its role. Boundary violations undermine the model's benefits.

---

*End of RFC-P1-03*
