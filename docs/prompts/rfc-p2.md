# 🧠 Claude Code Execution Plan

## RFC-P2 — Shared Components & Infrastructure Contracts

---

## **Objective**

Produce a **complete, enforceable RFC set** that defines:

* **Which platform components must be centralized**
* **What guarantees centralized components must provide**
* **How applications are allowed to consume shared infrastructure**
* **How entropy and per-app infra sprawl are permanently prevented**

Claude Code’s role is **documentation only**.

---

## **Global Constraints (Apply to ALL RFC-P2 Sections)**

### **Hard Rules**

* ❌ Do NOT design new infrastructure
* ❌ Do NOT recommend products or vendors
* ❌ Do NOT propose “better” architectures
* ❌ Do NOT soften requirements for convenience
* ❌ Do NOT introduce new abstractions beyond what is specified

### **Language Rules**

* Use **must / must not / shall**
* No “should”, “ideally”, or “recommended”
* Formal RFC tone
* No YAML, code, Helm, or implementation examples

### **Architecture Lock (Inherited from RFC-P1)**

* Capabilities are **explicit and target named resources**
* Determinism > speed
* Git defines intent, not runtime state
* Shared infrastructure is **platform-owned**
* Applications never own shared infra lifecycles

---

## **Execution Strategy**

RFC-P2 consists of **6 standalone documents**.

Claude Code must:

1. Generate **one document at a time**
2. Respect section boundaries strictly
3. Avoid leaking content across documents
4. Await human approval before proceeding

---

## **Phase 0 — Context Lock (One-Time Step)**

### **Step 0.1 — Load Context**

Claude Code must ingest:

* RFC-P1 (entirely)
* RFC-P2 structure (below)
* Explicit platform rules:

  * Shared infra exists to reduce entropy
  * Centralization is mandatory, not optional
  * Exceptions are rare and governed

### **Step 0.2 — Acknowledge Role**

Claude Code must internally confirm:

* It will not invent components
* It will not define HA/DR numbers arbitrarily
* It will not suggest technologies

If ambiguity exists → **document constraints, not solutions**

---

## **RFC-P2 Document Set**

---

## **P2-01 — Motivation & Problem Statement**

**Goal:** Explain *why* shared infrastructure must exist.

### Must Include

* Historical failure modes of per-app infra
* Operational pain (backups, upgrades, outages)
* Cost, reliability, and correctness risks
* Why decentralization breaks determinism

### Must NOT Include

* Eligibility criteria
* HA/DR requirements
* Capabilities
* Enforcement mechanisms

---

## **P2-02 — Shared Component Eligibility Criteria**

**Goal:** Define *when* a component must be centralized.

### Must Include

* Explicit eligibility rules (e.g., ≥3 consumers)
* Why these rules exist
* Why centralization is mandatory once criteria are met
* Exception philosophy (rare, explicit, reviewed)

### Must NOT Include

* Lists of specific components
* HA/DR requirements
* Enforcement details

---

## **P2-03 — Mandatory Guarantees for Shared Components**

**Goal:** Define *what guarantees* shared components must provide.

### Must Include

* Availability guarantees (conceptual, not numeric)
* Data durability guarantees
* Backup & recovery guarantees
* Upgrade and maintenance guarantees
* Contract stability expectations

### Must NOT Include

* Specific replica counts
* Vendor-specific features
* Implementation details

---

## **P2-04 — Capability Contracts for Shared Components**

**Goal:** Define *how* shared components expose guarantees.

### Must Include

* Shared components as **capability providers**
* Requirement for explicit, named capability contracts
* Stability and monotonicity expectations
* Consumer trust model

### Must NOT Include

* Capability schemas
* Readiness checks
* Event mechanics (already defined in RFC-P1)

---

## **P2-05 — Ownership & Lifecycle Rules**

**Goal:** Define *who owns what* and *who does not*.

### Must Include

* Platform ownership of shared infra
* Application consumption boundaries
* Modification authority
* Decommissioning responsibility

### Must NOT Include

* Git workflows
* Repo structure
* Namespace rules (RFC-P4 concern)

---

## **P2-06 — Explicit Anti-Patterns**

**Goal:** Prevent regression and entropy.

### Must Include

* Per-application databases
* Embedded infra inside app charts
* App-owned operators for shared services
* Hidden infra dependencies

Each anti-pattern must include:

* Why it occurs
* Why it is harmful
* Why it is forbidden

### Must NOT Include

* Alternatives
* Workarounds
* Exception processes

---

## **Phase 1 — Document Generation Loop**

For each P2 document:

### **Step N.1 — Scope Lock**

* Confirm the document answers **only** its question
* No overlap with other P2 or P1 documents

### **Step N.2 — Drafting**

* Write as a **standalone RFC**
* Include:

  * Title
  * Status
  * Audience
* No forward references to future RFCs except by ID

### **Step N.3 — Invariant Check**

Claude Code must internally verify:

* No design suggestions
* No vendor bias
* No implementation detail leakage
* No contradiction with RFC-P1

### **Step N.4 — Output**

* Output **only the RFC document**
* No commentary, no explanation, no summary

---

## **Phase 2 — Completion Criteria**

RFC-P2 is complete when:

* All 6 documents exist
* Each document is readable independently
* No document relies on tribal knowledge
* Platform engineers can determine:

  * what must be centralized
  * what guarantees are mandatory
  * what is strictly forbidden

---
