# RFC-P2-02 — Shared Component Eligibility Criteria

**Status:** Draft
**Audience:** Platform Engineers, Architects, Operations Teams

---

## 1. Introduction

This document defines when an infrastructure component must be centralized as shared platform infrastructure. It establishes explicit eligibility rules, explains why these rules exist, and articulates why centralization becomes mandatory once criteria are met. This document also addresses the philosophy governing exceptions to centralization requirements.

---

## 2. The Purpose of Eligibility Criteria

### 2.1 Criteria as Decision Boundaries

Eligibility criteria establish clear decision boundaries. When evaluating whether a component must be centralized, the criteria provide an unambiguous answer. The evaluation is mechanical: either the criteria are met, or they are not.

Decision boundaries eliminate subjective judgment. Without criteria, centralization decisions become matters of opinion. Different teams reach different conclusions based on different reasoning. Criteria replace opinion with determination.

### 2.2 Criteria as Forcing Functions

Eligibility criteria serve as forcing functions. They force early identification of shared infrastructure needs. They force explicit decisions rather than implicit assumptions. They force documentation of why a component is or is not centralized.

Forcing functions prevent drift. Without criteria, components that begin as single-use become multi-use without triggering centralization review. Criteria ensure that changes in usage trigger evaluation.

### 2.3 Criteria as Governance Tools

Eligibility criteria enable governance. Platform teams can audit component deployments against criteria. Non-compliant deployments can be identified. Remediation can be planned. Progress can be measured.

Governance requires measurability. Abstract principles cannot be audited. Concrete criteria can be audited. Criteria transform principles into actionable governance.

---

## 3. Eligibility Rules

### 3.1 Rule 1: Consumer Count Threshold

A component must be centralized when three or more distinct applications require the capability it provides.

**Application of the Rule:**

When a capability is required by a single application, that application may provide the capability for itself. When a capability is required by two applications, those applications may share infrastructure or each may provide its own, subject to platform review. When a capability is required by three or more applications, the capability must be provided by shared platform infrastructure.

**Rationale:**

A single consumer does not establish a pattern. Two consumers may represent coincidence or may represent an emerging pattern. Three consumers establish a pattern. Patterns must be served by platform infrastructure.

The threshold of three is deliberate. It is low enough to capture sharing opportunities early. It is high enough to avoid premature centralization of capabilities that do not demonstrate broad need.

### 3.2 Rule 2: Data Sharing Requirement

A component must be centralized when two or more distinct applications must access the same data.

**Application of the Rule:**

When data is created by one application and consumed by another, the infrastructure storing that data must be centralized. The consumer count threshold in Rule 1 does not apply; data sharing mandates centralization regardless of total consumer count.

**Rationale:**

Data sharing creates coupling. When applications share data through per-application infrastructure, they depend on that application's infrastructure. This dependency is implicit, fragile, and violates the capability model.

Shared data must reside in shared infrastructure. The alternative—applications accessing each other's infrastructure—creates ownership ambiguity, lifecycle coupling, and operational confusion.

### 3.3 Rule 3: Platform Dependency

A component must be centralized when the platform itself depends on the capability it provides.

**Application of the Rule:**

Capabilities required by platform operations—monitoring, logging, authentication, secret management, service discovery—must be centralized regardless of application consumer count. Platform dependencies are not counted as application consumers; they are a distinct eligibility trigger.

**Rationale:**

Platform capabilities are foundational. Applications depend on the platform. The platform depends on platform capabilities. Circular dependencies must be avoided; platform capabilities must be established before applications that use them.

Platform capabilities cannot be per-application. If each application deployed its own monitoring, the platform could not monitor itself. Platform capabilities must exist independently of any application.

### 3.4 Rule 4: Operational Criticality

A component must be centralized when its failure would impact multiple applications regardless of whether those applications directly consume its capability.

**Application of the Rule:**

Infrastructure whose failure cascades beyond direct consumers must be centralized. Network infrastructure, cluster services, storage infrastructure, and similar components must be centralized even if no application explicitly declares a dependency.

**Rationale:**

Operational criticality reflects implicit dependencies. Applications may not declare dependencies on DNS, but they fail when DNS fails. Applications may not declare dependencies on container networking, but they fail when networking fails.

Implicit dependencies must be managed centrally. The alternative—hoping that per-application infrastructure does not create implicit dependencies—is not a strategy.

### 3.5 Rule 5: Security Boundary Enforcement

A component must be centralized when it enforces security boundaries that applications must not control.

**Application of the Rule:**

Infrastructure that enforces authentication, authorization, encryption, network segmentation, audit logging, or compliance controls must be centralized. Applications must consume these capabilities; applications must not provide them for themselves.

**Rationale:**

Security boundaries require consistent enforcement. Per-application security infrastructure produces inconsistent enforcement. Inconsistent enforcement produces security gaps.

Security capabilities require independence from secured applications. An application must not control the infrastructure that secures it. Separation of concerns requires centralization.

---

## 4. Why These Rules Exist

### 4.1 Entropy Prevention

The eligibility rules exist to prevent entropy. RFC-P2-01 established that per-application infrastructure maximizes entropy. The eligibility rules identify the conditions under which entropy risk becomes unacceptable.

Entropy prevention requires early intervention. Once infrastructure proliferates, consolidation is costly and disruptive. The rules trigger centralization before proliferation occurs.

### 4.2 Capability Model Enforcement

The eligibility rules enforce the capability model defined in RFC-P1. Capabilities must be provided by named resources. Capabilities must be explicitly targeted. The eligibility rules identify when a capability must transition from application-provided to platform-provided.

The capability model requires providers. When multiple consumers need a capability, a provider must exist. Per-application infrastructure does not provide capabilities to the platform model; it hides them within applications.

### 4.3 Operational Sustainability

The eligibility rules protect operational sustainability. RFC-P2-01 established that per-application infrastructure distributes operational burden unsustainably. The eligibility rules identify when burden distribution exceeds sustainable limits.

Sustainability requires concentration. Operations that are distributed across many teams and many instances cannot be sustained at quality. The rules trigger concentration when distribution becomes unsustainable.

### 4.4 Cost Control

The eligibility rules enable cost control. RFC-P2-01 established that per-application infrastructure duplicates costs invisibly. The eligibility rules identify when duplication becomes significant.

Cost control requires visibility. Centralization creates visibility. Visibility enables optimization. The rules trigger centralization before hidden costs accumulate.

---

## 5. Mandatory Centralization

### 5.1 Criteria Met Means Centralization Required

When eligibility criteria are met, centralization is required. There is no discretion. There is no case-by-case evaluation. There is no weighing of factors. Criteria met means centralization required.

This is not a guideline. It is a rule. Rules are followed. Guidelines are considered. The eligibility criteria produce rules, not guidelines.

### 5.2 No Grandfather Clauses

Existing per-application infrastructure that meets eligibility criteria must be centralized. Prior existence does not exempt infrastructure from centralization requirements.

Grandfather clauses perpetuate problems. Infrastructure that was deployed before criteria existed is not less problematic than infrastructure deployed after. The problems documented in RFC-P2-01 apply equally.

### 5.3 No Deferral Without Exception

Centralization must not be deferred without a documented exception. "We will centralize later" is not acceptable. "We are too busy" is not acceptable. "It works fine as is" is not acceptable.

Deferral is denial. Deferred centralization does not occur. Backlogs grow. Priorities shift. Later never arrives. Centralization must occur when criteria are met, not when convenient.

### 5.4 Centralization Is Not Optional

The mandatory nature of centralization is not negotiable. Teams may not choose to operate their own infrastructure when eligibility criteria are met. The platform provides the capability; applications consume it.

Optional centralization produces partial centralization. Partial centralization produces the worst outcomes: some infrastructure is managed, some is not. The platform cannot make guarantees. Operations split across models. Complexity increases.

---

## 6. Exception Philosophy

### 6.1 Exceptions Are Rare

Exceptions to centralization requirements are rare. The default is centralization. Exceptions require justification.

Rarity is enforced through process, not aspiration. Exceptions must be documented. Exceptions must be reviewed. Exceptions must be time-bounded. These requirements make exceptions inconvenient. Inconvenience produces rarity.

### 6.2 Exceptions Are Explicit

Exceptions must be explicitly documented. The documentation must include:

- Which eligibility criteria are met
- Why centralization is not occurring despite criteria being met
- What risks the exception creates
- What compensating controls exist
- When the exception will be reviewed

Implicit exceptions do not exist. Undocumented non-centralization is non-compliance, not exception.

### 6.3 Exceptions Are Reviewed

Exceptions must be reviewed by platform governance. The review must determine:

- Whether the justification is valid
- Whether the risks are acceptable
- Whether the compensating controls are adequate
- Whether the exception period is appropriate

Unreviewed exceptions do not exist. An exception that has not been reviewed is not an exception; it is non-compliance awaiting discovery.

### 6.4 Exceptions Are Time-Bounded

Exceptions must have expiration dates. Permanent exceptions do not exist. Every exception must specify when it will be re-evaluated.

Time-bounding prevents exception accumulation. Without expiration, exceptions accumulate. The exception list grows. The exceptions become the rule. Time-bounding forces periodic reevaluation and eventual resolution.

### 6.5 Legitimate Exception Grounds

Exceptions may be granted for:

**Technical Impossibility:** The capability cannot be provided by shared infrastructure due to fundamental technical constraints. This is rare; most perceived impossibilities are actually inconveniences.

**Transition Period:** The capability is being transitioned to shared infrastructure, and the exception covers the transition period. The exception must specify the transition plan and completion criteria.

**Isolation Requirement:** The capability requires isolation from other consumers for security, compliance, or regulatory reasons. The isolation requirement must be documented and verified.

**Novel Capability:** The capability is new to the platform and does not yet have a shared implementation. The exception must specify the plan for developing shared capability.

### 6.6 Illegitimate Exception Grounds

Exceptions must not be granted for:

**Convenience:** Per-application infrastructure is more convenient than consuming shared infrastructure. Convenience is not a justification.

**Familiarity:** The team is familiar with their infrastructure and does not want to change. Familiarity is not a justification.

**Preference:** The team prefers their implementation over the platform implementation. Preference is not a justification.

**Timeline:** The team does not have time to transition to shared infrastructure. Timeline pressure does not override architectural requirements.

**Cost of Transition:** Transitioning to shared infrastructure would require effort. Transition cost is a planning input, not an exception justification.

---

## 7. Criteria Evaluation

### 7.1 When Evaluation Occurs

Eligibility criteria must be evaluated:

- When new infrastructure is proposed
- When new consumers are added to existing infrastructure
- When infrastructure ownership is transferred
- When applications are onboarded to the platform
- During periodic platform audits

Evaluation is not one-time. Infrastructure that was not eligible may become eligible. Continuous evaluation is required.

### 7.2 Who Performs Evaluation

Platform teams perform eligibility evaluation. Application teams do not self-evaluate. Self-evaluation produces motivated reasoning. Platform teams have no stake in the outcome and evaluate objectively.

Platform teams have authority to determine eligibility. Application teams may provide information. Application teams may not determine the outcome.

### 7.3 Evaluation Inputs

Evaluation requires:

- Inventory of infrastructure providing the capability
- Inventory of applications consuming the capability
- Mapping of data flows between applications
- Platform dependency analysis
- Cascade analysis for operational criticality
- Security boundary analysis

Incomplete inputs produce incomplete evaluation. Evaluation must not proceed until inputs are sufficient.

### 7.4 Evaluation Outputs

Evaluation produces:

- Eligibility determination (eligible or not eligible)
- Criteria that triggered eligibility (if eligible)
- Centralization timeline (if eligible)
- Exception request (if seeking exception)
- Audit trail documenting the evaluation

Evaluation outputs are permanent records. They document why infrastructure is centralized or why it is not. They enable audit and governance.

---

## 8. Summary

### 8.1 The Five Eligibility Rules

1. **Consumer Count:** Three or more applications require the capability
2. **Data Sharing:** Two or more applications must access the same data
3. **Platform Dependency:** The platform depends on the capability
4. **Operational Criticality:** Failure impacts multiple applications
5. **Security Boundary:** The component enforces security boundaries

### 8.2 The Centralization Mandate

When any eligibility rule is satisfied, centralization is mandatory. There is no discretion. There is no deferral. There are only compliance and documented exception.

### 8.3 The Exception Standard

Exceptions are rare, explicit, reviewed, and time-bounded. Exceptions require legitimate grounds. Convenience, familiarity, preference, timeline, and transition cost are not legitimate grounds.

---

*End of RFC-P2-02*
