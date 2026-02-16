# RFC-P1-01 — Problem Statement & Motivation

**Status:** Draft
**Audience:** Platform Engineers, Architects, Operations Teams

---

## 1. Introduction

This document describes the fundamental problems that necessitate a new approach to platform orchestration. It establishes the motivation for departing from established patterns and explains why existing solutions fail to meet correctness requirements.

---

## 2. Historical Pain

### 2.1 Shell Scripts and Procedural Orchestration

Platform deployments have historically relied on shell scripts to coordinate the ordering of resource creation. These scripts encode deployment sequences as imperative procedures. When a deployment fails partway through, the operator must determine the system state manually before restarting. The scripts themselves provide no mechanism for determining what has succeeded versus what has failed.

Shell scripts conflate orchestration logic with deployment logic. A script that installs a database and then configures an application embeds two distinct concerns: the ordering constraint (database before application) and the installation mechanics (how to deploy each). This conflation produces brittle systems where changes to either concern risk breaking the other.

### 2.2 Hook-Based Coordination

Many orchestration tools provide hook mechanisms: pre-install hooks, post-install hooks, pre-upgrade hooks. Hooks attempt to solve ordering problems by injecting procedural steps into declarative pipelines.

Hooks introduce hidden dependencies. The existence of a pre-install hook implies a dependency that is nowhere declared in the resource definitions themselves. Operators must examine hook definitions to understand what depends on what. The dependency graph exists only in the aggregate of multiple files, not as an explicit model.

Hooks are position-sensitive. A pre-install hook runs before installation; a post-install hook runs after. This positional coupling means that the meaning of a hook changes based on where it appears in a sequence. Moving a hook from one phase to another changes its semantics entirely.

### 2.3 Wait Jobs and Polling

A common pattern involves "wait jobs"—jobs that poll for a condition before allowing deployment to proceed. A wait job might poll a database endpoint until it responds, then exit successfully, unblocking the next deployment phase.

Wait jobs encode timing assumptions. A wait job that polls for 300 seconds assumes that 300 seconds is sufficient. If the dependency takes longer, the job fails. If it completes in 10 seconds, 290 seconds of polling capacity is wasted. The wait job provides no information about why it succeeded or failed, only that it did.

Wait jobs do not verify correctness. A database that accepts TCP connections is not necessarily a database that has completed initialization. A service that responds to health checks is not necessarily a service that is ready to serve traffic. Wait jobs test for observable conditions, not for semantic readiness.

---

## 3. Sync Waves Do Not Imply Correctness

### 3.1 The Ordering Fallacy

Sync waves provide a mechanism for ordering resource application within a deployment. Resources in wave 0 are applied before resources in wave 1. This ordering is enforced.

The enforcement of ordering does not imply the correctness of the result. Applying resource A before resource B guarantees only that the API server received A's manifest before B's manifest. It does not guarantee that A achieved any particular state before B was applied.

### 3.2 Application vs. Reconciliation

Applying a manifest and reconciling a manifest are distinct operations. Application submits a desired state to the API server. Reconciliation is the process by which controllers attempt to make actual state match desired state.

Sync waves order application. They do not order reconciliation. Resource A may be applied in wave 0, but its controller may not begin reconciliation until after resource B in wave 1 has already been applied. Sync waves provide sequencing at the wrong layer of abstraction.

### 3.3 The Gap Between Submission and Completion

A resource that has been submitted exists in desired state but not necessarily in actual state. The period between submission and reconciliation is undefined. No sync wave mechanism guarantees that this period has elapsed before the next wave begins.

This gap is the source of race conditions. When resource B depends on resource A, but sync waves only guarantee that A is submitted before B, B may observe A in a partially reconciled state. The dependency is not satisfied; the ordering merely created the appearance of satisfaction.

---

## 4. Healthy Does Not Mean Correct

### 4.1 Health as a Survival Signal

Health checks verify that a workload is alive. A healthy pod is a pod that has not crashed, has not been OOMKilled, and responds to probes. Health is a necessary condition for operation but not a sufficient condition for correctness.

### 4.2 Readiness as a Traffic Signal

Readiness checks verify that a workload is ready to receive traffic. A ready pod is a pod that has passed its readiness probe. Readiness is a Kubernetes construct designed for load balancer integration. It determines whether traffic is routed to a pod, not whether the pod is semantically correct.

### 4.3 Correctness as a Semantic Property

Correctness is domain-specific. A database is correct when its schema is initialized, its migrations have run, and its replication is established. A message queue is correct when its topics exist and its consumers are registered. A service mesh is correct when its certificates are issued and its sidecars are injected.

None of these correctness conditions are captured by health or readiness checks. A database pod may be healthy and ready while its schema remains uninitialized. The pod survives; it responds to probes; it accepts traffic. It is not correct.

### 4.4 The Observability Gap

Existing orchestration systems cannot observe correctness because they do not model correctness. They model health. They model readiness. They model sync status. Correctness exists outside the model.

When orchestration systems make decisions based on health, they make decisions based on incomplete information. A system that proceeds when dependencies are healthy may proceed when dependencies are not correct. The system operates on the information available, not the information required.

---

## 5. The Problem Is Modeling, Not Tooling

### 5.1 Tool Proliferation Does Not Address Model Deficiency

The response to orchestration failures has been tool proliferation. New tools promise better ordering. New tools promise better health checks. New tools promise better coordination. Each tool addresses symptoms without addressing the underlying deficiency.

The deficiency is not in the tools. The deficiency is in what the tools model. Tools that model health cannot produce correctness. Tools that model ordering cannot produce dependency satisfaction. The model determines the ceiling of what the tool can achieve.

### 5.2 The Missing Abstraction

Existing orchestration models lack an abstraction for semantic dependencies. They express "A before B" but not "A provides X, B requires X." They express "A is healthy" but not "A is ready to be consumed by B."

This missing abstraction forces operators to encode semantic dependencies as procedural steps. The operator knows that the database must be initialized before the application starts. The operator encodes this as a wait job, or a hook, or a sync wave. The knowledge exists in the operator's understanding, not in the system's model.

### 5.3 The Consequence of Model Poverty

When the model is impoverished, every deployment is an act of translation. The operator translates semantic requirements into the primitives the model provides. This translation is error-prone. It is also invisible—the semantic requirements are not preserved in the deployment artifacts.

When a deployment fails, the operator must reverse the translation. What did this wait job represent? What semantic requirement was this hook encoding? The answers exist only in documentation (if documented) or in the operator's memory (if remembered).

### 5.4 The Requirement for a Rich Model

The solution to orchestration failures is not better tooling for impoverished models. The solution is a richer model. A model that represents semantic dependencies directly. A model that distinguishes health from correctness. A model that captures the knowledge operators currently encode through procedural workarounds.

The problem is modeling. The problem has always been modeling. Until the model changes, the problems will persist regardless of which tools implement the model.

---

*End of RFC-P1-01*
