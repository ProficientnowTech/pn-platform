# RFC-P1-09 — Relationship with Argo Projects

**Status:** Draft
**Audience:** Platform Engineers, Architects, Operations Teams

---

## 1. Introduction

This document defines the responsibilities of each Argo project within the orchestration system and establishes explicit boundaries for what each project must and must not do. The Argo ecosystem provides multiple components—ArgoCD, Argo Workflows, and Argo Events—each with distinct purposes. This document specifies how the orchestration system uses each component within its defined role.

---

## 2. ArgoCD Responsibilities

### 2.1 Primary Role: GitOps Reconciler

ArgoCD serves as the GitOps reconciler. Its responsibility is to synchronize desired state (defined in Git) with actual state (in Kubernetes clusters). ArgoCD observes Git repositories, detects changes, and applies those changes to clusters.

ArgoCD operates the reconciliation loop: observe desired state, observe actual state, compute difference, apply changes to eliminate difference. This loop runs continuously for each Application ArgoCD manages.

### 2.2 Specific Responsibilities

ArgoCD is responsible for:

**Manifest Application:** ArgoCD applies Kubernetes manifests to clusters. It takes YAML definitions and creates, updates, or deletes Kubernetes resources accordingly.

**Drift Detection:** ArgoCD detects when cluster state differs from Git state. It identifies resources that have been modified in the cluster without corresponding Git changes.

**Sync Status Reporting:** ArgoCD reports whether each Application is synced, out-of-sync, progressing, or in an error state. This status reflects the relationship between Git and cluster.

**Health Status Reporting:** ArgoCD reports the health of Application resources based on Kubernetes health indicators. It aggregates pod health, deployment status, and other Kubernetes-native health signals.

**Resource Tracking:** ArgoCD tracks which Kubernetes resources belong to which Application. It maintains the mapping between Applications and their constituent resources.

### 2.3 What ArgoCD Provides to the Orchestrator

ArgoCD provides the orchestrator with:

**Sync Execution:** When the orchestrator determines an Application is ready, ArgoCD performs the sync. ArgoCD is the execution engine for applying desired state.

**Status Information:** ArgoCD provides sync status and health status. The orchestrator observes this status to track deployment progress.

**Resource Inventory:** ArgoCD knows which resources exist for each Application. This information supports observability and debugging.

### 2.4 What ArgoCD Does Not Provide

ArgoCD does not provide:

**Dependency Awareness:** ArgoCD does not know that Application B depends on Application A. ArgoCD syncs Applications independently.

**Cross-Application Coordination:** ArgoCD does not coordinate syncs across Applications. If A must sync before B, ArgoCD does not enforce this.

**Semantic Readiness:** ArgoCD does not know when an Application is semantically ready. ArgoCD knows sync status and health status, not correctness.

**Orchestration Logic:** ArgoCD does not decide what to sync or when. ArgoCD executes syncs; it does not plan them.

---

## 3. Argo Workflows Responsibilities

### 3.1 Primary Role: Workflow Execution Engine

Argo Workflows serves as the workflow execution engine. Its responsibility is to execute sequences of tasks, managing task dependencies, parallelism, and data passing between tasks.

Argo Workflows operates as a Kubernetes-native workflow engine. It runs tasks as containers, schedules them according to dependencies, and tracks their completion status.

### 3.2 Specific Responsibilities

Argo Workflows is responsible for:

**Task Execution:** Argo Workflows executes individual tasks as containers. Each task runs in isolation with defined inputs and outputs.

**Dependency Management Within Workflows:** Argo Workflows understands task dependencies within a workflow. If task B depends on task A, Argo Workflows ensures A completes before B starts.

**Parallelism Within Workflows:** Argo Workflows executes independent tasks in parallel. Tasks without mutual dependencies run concurrently.

**Workflow State Tracking:** Argo Workflows tracks workflow state: which tasks have completed, which are running, which are pending. It provides this state for observation.

**Retry and Error Handling:** Argo Workflows retries failed tasks according to configured policies. It handles transient failures within workflows.

### 3.3 What Argo Workflows Provides to the Orchestrator

Argo Workflows provides the orchestrator with:

**Complex Task Execution:** When the orchestrator needs to execute a multi-step task (such as verifying that a resource is semantically ready), Argo Workflows executes that task.

**Workflow Completion Signals:** When a workflow completes (successfully or not), Argo Workflows provides this outcome. The orchestrator observes completion and acts accordingly.

**Structured Task Results:** Argo Workflows can produce structured outputs from tasks. These outputs may inform orchestrator decisions.

### 3.4 What Argo Workflows Does Not Provide

Argo Workflows does not provide:

**Cross-Workflow Coordination:** Argo Workflows does not coordinate between separate workflows. If workflow X must complete before workflow Y, Argo Workflows does not enforce this.

**Deployment Decision Logic:** Argo Workflows does not decide what to deploy or when. Argo Workflows executes workflows; the orchestrator decides when to submit them.

**Capability Model Awareness:** Argo Workflows does not understand capabilities, providers, or consumers. Argo Workflows executes tasks; it does not know why those tasks matter.

**Persistent Orchestration State:** Argo Workflows maintains workflow state, not orchestration state. The orchestrator's understanding of deployment progress is separate from Argo Workflows' understanding of workflow progress.

---

## 4. Argo Events Responsibilities

### 4.1 Primary Role: Event-Driven Automation

Argo Events serves as the event-driven automation layer. Its responsibility is to connect event sources to event consumers, enabling actions to be triggered by events.

Argo Events operates as an event bus and trigger system. It receives events from various sources, evaluates trigger conditions, and initiates actions when conditions are met.

### 4.2 Specific Responsibilities

Argo Events is responsible for:

**Event Ingestion:** Argo Events receives events from configured sources. Sources may include webhooks, message queues, Kubernetes resource changes, and other event producers.

**Event Routing:** Argo Events routes events to interested consumers. Events are matched to triggers based on configured criteria.

**Trigger Evaluation:** Argo Events evaluates trigger conditions. When an event matches a trigger's conditions, the trigger fires.

**Action Initiation:** Argo Events initiates actions when triggers fire. Actions may include creating Kubernetes resources, submitting Argo Workflows, or sending HTTP requests.

### 4.3 What Argo Events Provides to the Orchestrator

Argo Events provides the orchestrator with:

**Event Delivery:** When events occur in the system (a resource provides a capability, a sync completes, a verification succeeds), Argo Events delivers these events to the orchestrator.

**Decoupled Event Production:** Event producers do not need to know about the orchestrator. They emit events; Argo Events delivers them. This decoupling enables loose integration.

**Trigger-Based Automation:** When specific events occur, Argo Events can automatically trigger orchestrator actions. The orchestrator can be event-driven without implementing its own event infrastructure.

### 4.4 What Argo Events Does Not Provide

Argo Events does not provide:

**Orchestration Logic:** Argo Events does not understand orchestration. It delivers events and fires triggers; it does not decide what those events mean for deployment progress.

**Dependency Graph Awareness:** Argo Events does not know the dependency graph. It cannot determine whether a resource is ready based on its dependencies.

**State Management:** Argo Events is stateless with respect to orchestration. It does not track which resources have completed or which capabilities have been provided.

**Event Interpretation:** Argo Events delivers events; it does not interpret them. Determining what an event means for orchestration is the orchestrator's responsibility.

---

## 5. Responsibility Boundaries

### 5.1 The Orchestrator's Unique Responsibilities

The orchestrator has responsibilities that no Argo component provides:

**Dependency Graph Management:** The orchestrator maintains the dependency graph. It knows which resources provide which capabilities and which resources require them.

**Orchestration Decisions:** The orchestrator decides when resources may proceed. It evaluates dependency satisfaction and releases work accordingly.

**Capability Tracking:** The orchestrator tracks capability provision. It knows which capabilities have been provided and which remain unresolved.

**Cross-Application Coordination:** The orchestrator coordinates across Applications. It enforces ordering and dependencies that span multiple ArgoCD Applications.

**Semantic Readiness Determination:** The orchestrator determines semantic readiness. It knows when a resource is correct, not just healthy or synced.

### 5.2 Boundary Enforcement

Each component must stay within its boundaries:

**ArgoCD must not orchestrate.** ArgoCD must not delay syncs waiting for other Applications. ArgoCD must not evaluate cross-Application dependencies. ArgoCD syncs what it is told to sync.

**Argo Workflows must not orchestrate.** Argo Workflows must not maintain deployment state across workflow executions. Argo Workflows must not decide which workflows to run based on orchestration state.

**Argo Events must not orchestrate.** Argo Events must not make decisions about deployment ordering. Argo Events must not interpret events in terms of capability satisfaction.

**The orchestrator must not reconcile.** The orchestrator must not apply manifests directly. The orchestrator must not maintain sync state. The orchestrator uses ArgoCD for reconciliation.

### 5.3 Why Boundaries Matter

Boundary enforcement enables:

**Clear Responsibility:** Each component has a defined purpose. Debugging is easier when responsibilities are clear.

**Independent Evolution:** Components can be upgraded independently. ArgoCD improvements do not require orchestrator changes if boundaries are respected.

**Replaceability:** Components can be replaced. If a better reconciler than ArgoCD emerges, it can be substituted without rewriting the orchestrator.

**Testability:** Components can be tested in isolation. The orchestrator can be tested without ArgoCD. ArgoCD can be tested without the orchestrator.

---

## 6. Explicit Prohibitions

### 6.1 ArgoCD Prohibitions

ArgoCD must not be used for:

**Sync Wave-Based Orchestration:** Sync waves must not be used to enforce cross-Application dependencies. Sync waves operate within Applications; they cannot provide cross-Application guarantees.

**Hook-Based Coordination:** Hooks must not be used to wait for external dependencies or coordinate with other Applications. Hooks are procedural insertions that violate the orchestration model.

**Health-Based Dependency Satisfaction:** ArgoCD health status must not be used as the signal for dependency satisfaction. Health indicates survival, not correctness.

**Application-to-Application Dependencies:** ArgoCD Application dependencies (if any exist) must not be used. Applications do not depend on Applications; resources require capabilities.

### 6.2 Argo Workflows Prohibitions

Argo Workflows must not be used for:

**Orchestration State Management:** Workflow state must not be used as a substitute for orchestration state. Workflow completion is input to the orchestrator, not the orchestrator's state.

**Deployment Ordering Logic:** Workflows must not encode "deploy A then deploy B" logic. The orchestrator determines ordering; workflows execute tasks.

**Polling for Readiness:** Workflows must not poll external systems waiting for readiness. Polling is inefficient and races against event-driven notification.

**Long-Running Coordination Workflows:** Workflows must not run for the duration of a deployment to coordinate it. The orchestrator coordinates; workflows execute bounded tasks.

### 6.3 Argo Events Prohibitions

Argo Events must not be used for:

**Stateful Orchestration:** Argo Events must not accumulate state across events to make orchestration decisions. Argo Events is stateless; the orchestrator maintains state.

**Dependency Resolution:** Argo Events must not evaluate whether dependencies are satisfied. Argo Events routes events; the orchestrator interprets them.

**Direct ArgoCD Triggering Based on Events:** Argo Events must not directly trigger ArgoCD syncs without orchestrator involvement. The orchestrator must mediate to ensure dependencies are satisfied.

**Complex Conditional Logic:** Argo Events triggers must not contain complex conditions that effectively implement orchestration logic. Simple routing is acceptable; decision logic belongs in the orchestrator.

### 6.4 General Prohibitions

Across all Argo components:

**No Orchestration Logic in Argo Components:** Orchestration logic must reside in the orchestrator, not scattered across ArgoCD configurations, Workflow definitions, and Event triggers.

**No Implicit Dependencies:** Dependencies must not be encoded implicitly through component configurations. All dependencies must be explicit in the orchestrator's model.

**No Component Coupling:** Argo components must not be tightly coupled to each other in ways that bypass the orchestrator. Communication flows through events; decisions flow through the orchestrator.

---

## 7. Integration Model

### 7.1 How Components Interact

The components interact through the orchestrator:

1. The orchestrator evaluates the dependency graph.
2. The orchestrator determines a resource is ready.
3. The orchestrator triggers an ArgoCD sync (via ArgoCD's API or through Argo Events).
4. ArgoCD performs the sync and reports completion.
5. The completion event flows to the orchestrator (via Argo Events).
6. The orchestrator triggers a verification workflow (via Argo Workflows).
7. Argo Workflows executes the verification and reports the result.
8. The result event flows to the orchestrator (via Argo Events).
9. The orchestrator updates its state and re-evaluates the dependency graph.
10. The cycle repeats for newly ready resources.

### 7.2 The Orchestrator as Central Authority

The orchestrator is the central authority for deployment decisions. It alone determines what is ready, what may proceed, and what must wait.

Argo components are execution engines and event infrastructure. They do not make deployment decisions. They execute decisions made by the orchestrator and report outcomes.

This centralization is not a limitation; it is a feature. A single authority for orchestration decisions eliminates conflicts, races, and inconsistencies that arise when multiple components independently decide what to do.

### 7.3 Event-Driven Integration

Integration is event-driven. Components communicate through events, not synchronous calls.

The orchestrator does not poll ArgoCD for sync status. ArgoCD emits events when sync status changes; the orchestrator observes them.

The orchestrator does not poll Argo Workflows for completion. Workflows emit events when they complete; the orchestrator observes them.

Event-driven integration enables loose coupling and asynchronous operation, consistent with the orchestration system's execution model.

---

## 8. Summary

### 8.1 Role Summary

| Component | Primary Role | Must Do | Must Not Do |
|-----------|--------------|---------|-------------|
| ArgoCD | GitOps Reconciler | Apply manifests, report status | Orchestrate, enforce dependencies |
| Argo Workflows | Workflow Engine | Execute tasks, report completion | Maintain orchestration state |
| Argo Events | Event Router | Deliver events, fire triggers | Make orchestration decisions |
| Orchestrator | Deployment Coordinator | Evaluate dependencies, release work | Apply manifests, execute tasks |

### 8.2 The Key Insight

Each Argo component does one thing well. ArgoCD reconciles. Argo Workflows executes. Argo Events routes. None of them orchestrates.

Orchestration is the orchestrator's job. The orchestrator uses the Argo components as tools, each for its intended purpose. This division of labor enables each component to excel at its specialty while the orchestrator provides the coordination layer none of them offers.

---

*End of RFC-P1-09*
