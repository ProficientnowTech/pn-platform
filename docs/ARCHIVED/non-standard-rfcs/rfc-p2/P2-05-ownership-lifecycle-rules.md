# RFC-P2-05 — Ownership & Lifecycle Rules

**Status:** Draft
**Audience:** Platform Engineers, Architects, Operations Teams

---

## 1. Introduction

This document defines ownership and lifecycle rules for shared infrastructure. It establishes that the platform owns shared infrastructure, defines the boundaries within which applications may consume shared infrastructure, specifies who has authority to modify shared infrastructure, and assigns responsibility for decommissioning. Clear ownership prevents ambiguity, conflicting actions, and accountability gaps.

---

## 2. The Necessity of Clear Ownership

### 2.1 Ownership Defines Responsibility

Ownership defines who is responsible. The owner is responsible for the existence, operation, maintenance, and eventual removal of what they own. Without clear ownership, responsibility is diffuse. Diffuse responsibility is no responsibility.

When no one owns infrastructure, no one maintains it. When everyone owns infrastructure, no one is accountable. Ownership must be singular and explicit.

### 2.2 Ownership Defines Authority

Ownership defines who has authority to act. The owner decides how infrastructure is configured. The owner decides when infrastructure is modified. The owner decides if infrastructure is removed. Non-owners do not have this authority.

Authority without ownership creates conflict. Multiple parties making decisions about the same infrastructure produces inconsistent state. Ownership consolidates authority to prevent conflict.

### 2.3 Ownership Defines Accountability

Ownership defines who is accountable for outcomes. When infrastructure fails, the owner is accountable. When infrastructure causes problems, the owner is accountable. Accountability cannot be assigned without ownership.

Accountability requires authority. Holding someone accountable for infrastructure they do not control is unjust. Ownership aligns authority and accountability.

### 2.4 Ambiguous Ownership Is Prohibited

Ownership must never be ambiguous. For every piece of shared infrastructure, there must be exactly one owner. The owner must be identifiable. The ownership must be documented.

Ambiguous ownership produces:

**Inaction:** When ownership is unclear, parties assume others will act. No one acts.

**Conflict:** When ownership is unclear, multiple parties may act. Their actions conflict.

**Blame Shifting:** When ownership is unclear, accountability cannot be assigned. Problems persist without resolution.

---

## 3. Platform Ownership of Shared Infrastructure

### 3.1 The Platform as Owner

The platform owns all shared infrastructure. Shared infrastructure is platform infrastructure. The platform team is responsible for shared infrastructure existence, operation, maintenance, and removal.

This ownership is not delegation. The platform does not own shared infrastructure on behalf of applications. The platform owns shared infrastructure because shared infrastructure is a platform concern. Applications are consumers, not owners.

### 3.2 Scope of Platform Ownership

Platform ownership encompasses:

**Existence:** The platform decides what shared infrastructure exists. The platform provisions shared infrastructure. The platform determines capacity.

**Configuration:** The platform configures shared infrastructure. Configuration includes security settings, performance parameters, operational policies, and all other settings.

**Operation:** The platform operates shared infrastructure. Operation includes monitoring, alerting, incident response, and day-to-day management.

**Maintenance:** The platform maintains shared infrastructure. Maintenance includes patching, upgrades, backup verification, and all activities that keep infrastructure healthy.

**Lifecycle:** The platform controls shared infrastructure lifecycle. The platform decides when infrastructure is created, modified, and removed.

### 3.3 Platform Ownership Obligations

Ownership creates obligations. The platform must:

**Provide Capabilities:** The platform must ensure shared infrastructure provides the capabilities consumers require, per the contracts defined in RFC-P2-04.

**Meet Guarantees:** The platform must ensure shared infrastructure meets the guarantees defined in RFC-P2-03.

**Support Consumers:** The platform must support consumers who experience problems with shared infrastructure.

**Communicate Changes:** The platform must communicate changes that affect consumers.

**Maintain Documentation:** The platform must maintain documentation of shared infrastructure capabilities, contracts, and operational status.

### 3.4 Platform Authority

Platform ownership confers authority. The platform has exclusive authority to:

**Provision Infrastructure:** Only the platform may create shared infrastructure.

**Configure Infrastructure:** Only the platform may configure shared infrastructure.

**Modify Infrastructure:** Only the platform may change shared infrastructure.

**Remove Infrastructure:** Only the platform may decommission shared infrastructure.

This authority is not delegable. The platform may not grant applications authority over shared infrastructure. Granting such authority would create the ownership ambiguity this RFC prohibits.

---

## 4. Application Consumption Boundaries

### 4.1 Applications as Consumers

Applications consume shared infrastructure. They do not own it. They do not control it. They use capabilities that shared infrastructure provides.

The consumer role is limited. Consumers may:

**Declare Dependencies:** Consumers may declare that they require capabilities from shared infrastructure.

**Access Capabilities:** Consumers may access capabilities through defined interfaces.

**Use Capabilities:** Consumers may use capabilities within the bounds of capability contracts.

### 4.2 What Applications May Do

Applications may:

**Request Access:** Applications may request access to shared infrastructure capabilities. Access is granted through defined processes.

**Use Interfaces:** Applications may use the interfaces that shared infrastructure exposes. Interfaces are defined in capability contracts.

**Store Data:** Applications may store data in shared infrastructure designed for data storage. The data belongs to the application; the infrastructure belongs to the platform.

**Report Problems:** Applications may report problems with shared infrastructure. The platform investigates and remediates.

**Request Changes:** Applications may request changes to shared infrastructure. Requests are evaluated and acted upon by the platform.

### 4.3 What Applications May Not Do

Applications may not:

**Provision Infrastructure:** Applications may not create shared infrastructure. Infrastructure creation is a platform function.

**Configure Infrastructure:** Applications may not configure shared infrastructure. Configuration is a platform function.

**Modify Infrastructure:** Applications may not modify shared infrastructure directly. Modifications occur through the platform.

**Access Implementation:** Applications may not access shared infrastructure implementation details. Applications interact through defined interfaces only.

**Bypass Contracts:** Applications may not use capabilities in ways not specified by contracts. Contract boundaries are absolute.

**Assume Control:** Applications may not assume operational control of shared infrastructure. Operations remain with the platform.

### 4.4 Boundary Enforcement

Consumption boundaries must be enforced. Enforcement prevents applications from exceeding their consumer role.

Enforcement mechanisms include:

**Access Controls:** Applications receive only the access necessary to consume capabilities. Administrative access is not granted.

**Interface Restrictions:** Applications can only reach shared infrastructure through defined interfaces. Direct access to implementation is blocked.

**Audit:** Application interactions with shared infrastructure are logged. Boundary violations are detected.

**Policy:** Organizational policy prohibits boundary violations. Violations have consequences.

### 4.5 Boundary Rationale

Boundaries exist to:

**Preserve Ownership:** If applications could modify shared infrastructure, ownership would be compromised. Boundaries preserve platform ownership.

**Protect Stability:** Application modifications could destabilize shared infrastructure. Boundaries protect other consumers.

**Enable Guarantees:** The platform can only guarantee what it controls. Boundaries ensure the platform controls shared infrastructure.

**Simplify Operations:** Clear boundaries simplify operational models. The platform operates infrastructure; applications operate applications.

---

## 5. Modification Authority

### 5.1 Exclusive Platform Authority

The platform has exclusive authority to modify shared infrastructure. No other party may modify shared infrastructure. This authority is not shared.

Modification includes:

**Configuration Changes:** Any change to infrastructure configuration.

**Version Changes:** Upgrades, downgrades, and patches.

**Capacity Changes:** Scaling, resource allocation, and capacity adjustments.

**Structural Changes:** Topology changes, component additions, component removals.

### 5.2 Modification Process

Modifications must follow defined processes. Processes ensure:

**Review:** Modifications are reviewed before implementation. Review catches errors and validates approach.

**Approval:** Modifications are approved by appropriate authority. Approval confirms authorization.

**Testing:** Modifications are tested before production application. Testing validates behavior.

**Communication:** Modifications are communicated to affected consumers. Communication enables preparation.

**Rollback:** Modifications have rollback plans. Rollback enables recovery from failed modifications.

### 5.3 Emergency Modifications

Emergency modifications may bypass standard processes when:

**Immediate Risk:** Unmodified infrastructure poses immediate risk to availability, security, or data integrity.

**Time Constraint:** Standard process timing is incompatible with the urgency of the risk.

Emergency modifications must still:

**Be Documented:** Emergency modifications must be documented, even if after the fact.

**Be Reviewed:** Emergency modifications must be reviewed retrospectively.

**Follow Up:** Standard process must be completed after emergency has passed.

Emergency is not routine. Frequent emergency modifications indicate process failure or infrastructure instability. Both require correction.

### 5.4 Consumer-Requested Modifications

Consumers may request modifications to shared infrastructure. Requests are:

**Evaluated:** The platform evaluates whether the request is appropriate and feasible.

**Prioritized:** Appropriate requests are prioritized against other work.

**Scheduled:** Prioritized requests are scheduled for implementation.

**Implemented:** The platform implements approved requests.

**Communicated:** Implementation is communicated to the requesting consumer.

Consumer requests do not confer authority. Consumers request; the platform decides and acts.

### 5.5 Prohibited Modifications

Certain modifications are prohibited regardless of who requests them:

**Contract Violations:** Modifications that would violate capability contracts are prohibited.

**Guarantee Reductions:** Modifications that would weaken guarantees are prohibited per RFC-P2-04 monotonicity requirements.

**Consumer Breakage:** Modifications that would break consumers without proper deprecation are prohibited.

**Security Degradation:** Modifications that would reduce security posture are prohibited.

---

## 6. Decommissioning Responsibility

### 6.1 Platform Decommissioning Authority

The platform has exclusive authority to decommission shared infrastructure. No other party may decommission shared infrastructure. Decommissioning is a platform function.

Decommissioning includes:

**Capability Retirement:** Removing capabilities that are no longer needed.

**Infrastructure Removal:** Removing infrastructure that no longer provides value.

**Data Disposition:** Handling data stored in decommissioned infrastructure.

**Resource Reclamation:** Recovering resources consumed by decommissioned infrastructure.

### 6.2 Decommissioning Prerequisites

Decommissioning may proceed only when:

**No Active Consumers:** Zero consumers actively depend on the infrastructure being decommissioned.

**Deprecation Complete:** If consumers previously existed, deprecation period has concluded.

**Data Handled:** Data in the infrastructure has been migrated, archived, or properly disposed.

**Dependencies Resolved:** Infrastructure that depended on the decommissioned infrastructure has been updated.

Prerequisites must be verified. Decommissioning without verification risks breaking consumers and losing data.

### 6.3 Consumer Migration

When infrastructure is being decommissioned, consumers must migrate to alternatives. Migration is:

**Consumer Responsibility:** Consumers are responsible for modifying their applications to use alternative capabilities.

**Platform Supported:** The platform provides migration guidance, alternative capabilities, and transition support.

**Time Bounded:** Migration must complete within the deprecation period.

**Verified:** Consumer migration must be verified before decommissioning proceeds.

### 6.4 Data Handling

Data in decommissioned infrastructure must be handled appropriately:

**Consumer Data:** Data belonging to consumers must be migrated by consumers or disposed according to consumer direction.

**Platform Data:** Data belonging to the platform must be archived or disposed according to retention policies.

**Sensitive Data:** Sensitive data must be securely disposed. Decommissioned storage must not contain recoverable sensitive data.

**Verification:** Data disposition must be verified. Unverified disposition is incomplete disposition.

### 6.5 Decommissioning Documentation

Decommissioning must be documented:

**Decision:** The decision to decommission must be documented, including rationale.

**Plan:** The decommissioning plan must be documented, including timeline and steps.

**Consumer Communication:** Consumer notifications must be documented.

**Execution:** Execution of decommissioning steps must be documented.

**Completion:** Completion of decommissioning must be documented and verified.

Documentation enables audit and provides reference for future decommissioning efforts.

### 6.6 Premature Decommissioning Prohibition

Infrastructure must not be decommissioned while consumers depend on it. Premature decommissioning breaks consumers. Breaking consumers violates platform obligations.

Pressure to decommission is not justification. Cost pressure, resource pressure, and schedule pressure do not override consumer dependencies. Consumers must migrate before decommissioning proceeds.

---

## 7. Ownership Transitions

### 7.1 When Transitions Occur

Ownership transitions occur when:

**Centralization:** Per-application infrastructure meeting RFC-P2-02 eligibility criteria transitions to platform ownership.

**Organizational Change:** Platform team restructuring transfers ownership between platform groups.

**Technology Change:** Infrastructure replacement transfers ownership from old infrastructure to new.

### 7.2 Transition Process

Ownership transitions require:

**Clear Handoff:** The previous owner and new owner must explicitly agree on the transition.

**Documentation Transfer:** All documentation must transfer to the new owner.

**Knowledge Transfer:** Operational knowledge must transfer to the new owner.

**Consumer Notification:** Consumers must be notified of ownership change.

**Responsibility Transfer:** Responsibility transfers completely. The previous owner has no residual responsibility after transition.

### 7.3 No Partial Ownership

Ownership is complete or nonexistent. Partial ownership is prohibited. There is no "shared ownership" or "joint ownership."

During transitions, ownership transfers completely at a defined moment. Before that moment, the previous owner is responsible. After that moment, the new owner is responsible. There is no overlap and no gap.

### 7.4 Transition Documentation

Transitions must be documented:

**Previous Owner:** Who owned the infrastructure before transition.

**New Owner:** Who owns the infrastructure after transition.

**Transition Date:** When ownership transferred.

**Scope:** What infrastructure was transferred.

**Rationale:** Why the transition occurred.

---

## 8. Summary

### 8.1 Ownership Principles

- Ownership must be clear, singular, and documented
- The platform owns all shared infrastructure
- Applications are consumers, not owners
- Ownership defines responsibility, authority, and accountability

### 8.2 Authority Distribution

| Function | Platform | Application |
|----------|----------|-------------|
| Provision infrastructure | Yes | No |
| Configure infrastructure | Yes | No |
| Modify infrastructure | Yes | No |
| Decommission infrastructure | Yes | No |
| Declare dependencies | No | Yes |
| Access capabilities | No | Yes |
| Use capabilities | No | Yes |
| Request changes | No | Yes |

### 8.3 Lifecycle Control

The platform controls all shared infrastructure lifecycle:
- Creation and provisioning
- Configuration and modification
- Maintenance and operation
- Deprecation and decommissioning

Applications consume capabilities but do not control the infrastructure providing them.

---

*End of RFC-P2-05*
