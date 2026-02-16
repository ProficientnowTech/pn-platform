# 🧠 Claude Code Execution Plan

## RFC-P1 — Platform Orchestration & Convergence

---

## **Objective**

Generate **10 standalone RFC documents (P1-01 → P1-10)** that **faithfully document** an already-designed capability-based, event-driven platform orchestration system.

Claude Code is **not allowed** to design, invent, optimize, or reinterpret the system.

---

## **Global Constraints (Apply to ALL Steps)**

### **Hard Rules**

* Do NOT design or propose alternatives
* Do NOT introduce new concepts or terminology
* Do NOT add tooling beyond what is explicitly referenced
* Do NOT include YAML, code, or configuration
* Do NOT merge sections
* Do NOT cross-pollinate content between sections

### **Language Rules**

* Use **must / must not**, never “should”
* Be explicit, even if repetitive
* Write in formal RFC tone
* Avoid examples unless explicitly allowed by the section

### **Architecture Lock**

The following are immutable facts:

* Orchestration is **capability-based**
* Execution is **event-driven and asynchronous**
* Capabilities target **explicit, named resources**
* ArgoCD is **only a reconciler**
* No phases, no stacks, no polling, no hooks, no scripts

---

## **Execution Strategy**

Claude Code must operate in **strict sequence**, one document at a time.

Each document must be:

* Generated
* Reviewed
* Approved (or corrected)
  before moving to the next.

---

## **Phase 0 — Context Lock (One-Time Step)**

### **Step 0.1 — Load Design Context**

Claude Code must ingest:

* The Master RFC-P1 Authoring Prompt
* The agreed RFC structure (P1-01 → P1-10)
* The explicit prohibitions and invariants

### **Step 0.2 — Acknowledge Lock**

Claude Code must confirm (internally) that:

* It will not design
* It will not simplify
* It will not “helpfully” improve anything

If ambiguity exists, Claude Code must **document constraints**, not invent solutions.

---

## **Phase 1 — Document Generation Loop**

Repeat the following steps **exactly 10 times**, once per section.

---

### **Generic Step Template (Applies to Every Section)**

#### **Step N.1 — Section Boundary Enforcement**

* Only cover the scope defined for this section
* Explicitly exclude concerns belonging to other sections
* No forward-looking design

#### **Step N.2 — Content Drafting**

* Write the section as a **standalone RFC document**
* Include:

  * Title
  * Status
  * Audience
  * Section-specific content only

#### **Step N.3 — Invariant Validation**

Before finalizing, Claude Code must internally check:

* No violation of global constraints
* No forbidden patterns
* No accidental design decisions
* No tooling bias

#### **Step N.4 — Output**

* Output **only the RFC document**
* No commentary
* No explanation
* No summary of future work

---

## **Phase 2 — Section-Specific Instructions**

Below are **Claude Code instructions per section**.

---

### **P1-01 — Problem Statement & Motivation**

**Goal:** Explain *why* this system exists.

Must include:

* Historical pain (bash, hooks, wait jobs)
* Sync waves ≠ correctness
* “Healthy” ≠ “Correct”
* Why the problem is modeling, not tooling

Must NOT include:

* Capabilities
* Events
* Argo internals
* Solutions

---

### **P1-02 — Design Goals, Non-Goals & Invariants**

**Goal:** Define the boundaries of the system.

Must include:

* Determinism definition
* Zero-human-intervention definition
* Explicit non-goals
* Hard invariants

Must NOT include:

* Execution details
* Event models
* Examples

---

### **P1-03 — Conceptual Model**

**Goal:** Establish mental model.

Must include:

* Reconciliation vs orchestration
* Why orchestration is external to ArgoCD
* System roles at a conceptual level

Must NOT include:

* Capabilities schema
* Events
* Failure handling

---

### **P1-04 — Capability Model**

**Goal:** Define capability abstraction.

Must include:

* Capability definition
* Provider / consumer
* Explicit resource targeting requirement
* Why apps don’t depend on apps

Must NOT include:

* Readiness checks
* Events
* Workflows

---

### **P1-05 — Readiness & Correctness Semantics**

**Goal:** Define correctness.

Must include:

* Health vs readiness vs correctness
* Why Kubernetes readiness is insufficient
* Definition of “safe to consume”

Must NOT include:

* Events
* Execution order
* Tooling

---

### **P1-06 — Event Model**

**Goal:** Define facts & transitions.

Must include:

* Events as immutable facts
* Replay semantics
* Idempotency
* Duplication tolerance

Must NOT include:

* Workflow execution
* Tools
* Dependency resolution

---

### **P1-07 — Orchestration Execution Semantics**

**Goal:** Define how progress happens.

Must include:

* Asynchronous execution
* Local dependency resolution
* Parallelism guarantees
* Explicit rejection of phases/stacks

Must NOT include:

* Failure recovery
* Tool mapping

---

### **P1-08 — Failure Semantics & Recovery**

**Goal:** Define resilience.

Must include:

* Unresolved capabilities
* Partial failures
* Replay & rebuild
* Deterministic recovery

Must NOT include:

* Event internals
* Argo specifics

---

### **P1-09 — Relationship with Argo Projects**

**Goal:** Define responsibility boundaries.

Must include:

* ArgoCD responsibilities
* Argo Workflows responsibilities
* Argo Events responsibilities
* Explicit prohibitions

Must NOT include:

* Capability logic
* Readiness semantics

---

### **P1-10 — Explicit Prohibitions**

**Goal:** Prevent regression.

Must include:

* Forbidden patterns list
* Why each is forbidden
* Conceptual alternatives (non-design)

Must NOT include:

* New ideas
* Solutions

---

## **Phase 3 — Completion Criteria**

RFC-P1 is considered complete when:

* All 10 documents exist
* Each document is standalone
* No document contradicts another
* No document introduces design drift
* No document relies on tribal knowledge

---
