# RFC-P2-01 — Motivation & Problem Statement

**Status:** Draft
**Audience:** Platform Engineers, Architects, Operations Teams

---

## 1. Introduction

This document explains why shared infrastructure must exist as a platform-owned concern. It establishes the historical failure modes that necessitate centralization, the operational costs of per-application infrastructure, and why decentralized infrastructure ownership breaks the determinism guarantees established in RFC-P1.

---

## 2. Historical Failure Modes of Per-Application Infrastructure

### 2.1 Proliferation Without Governance

When applications are permitted to deploy their own infrastructure components, proliferation occurs without constraint. Each team deploys what it needs when it needs it. There is no central inventory of what exists. There is no shared understanding of what is running or why.

This proliferation is not a gradual problem. It is exponential. The first team deploys a database. The second team deploys a different database because they did not know the first existed. The third team deploys a third database because the first two do not meet their specific requirements. By the time governance is attempted, the proliferation has exceeded the capacity to catalog it.

### 2.2 Configuration Drift

Per-application infrastructure drifts from any baseline that may have existed at creation. Team A deploys a database with specific security settings. Over months, those settings are modified to address immediate needs. The modifications are not tracked. The original configuration is lost. No one knows what the current configuration is supposed to be.

Drift compounds across instances. When multiple teams deploy similar infrastructure, drift occurs independently in each instance. The instances that started identically become progressively different. Comparing configurations becomes impossible because there is no source of truth for what any configuration ought to be.

### 2.3 Knowledge Fragmentation

Per-application infrastructure fragments operational knowledge. The engineer who deployed a database may leave the organization. The documentation may not exist. The tribal knowledge of how that database was configured, why specific choices were made, and what depends on it leaves with the engineer.

Knowledge fragmentation creates operational blind spots. When an incident occurs, responders must reverse-engineer the infrastructure before they can diagnose the problem. The time spent understanding what exists is time not spent resolving the incident.

### 2.4 Inconsistent Security Postures

Per-application infrastructure produces inconsistent security postures. Team A configures encryption. Team B does not. Team C configures authentication but misconfigures authorization. There is no way to assert that all databases meet security requirements because there is no shared definition of those requirements and no mechanism to enforce them.

Security gaps compound over time. Initial deployments may meet standards. Subsequent modifications may introduce vulnerabilities. Without centralized oversight, vulnerabilities accumulate undetected.

### 2.5 Version Sprawl

Per-application infrastructure produces version sprawl. Teams deploy the version available when they deploy. Teams do not upgrade unless forced to by a specific requirement. The platform accumulates multiple versions of the same infrastructure type, each with different capabilities, different bugs, and different security vulnerabilities.

Version sprawl complicates operations. Procedures that work for version X do not work for version Y. Runbooks must account for multiple versions. Operators must know which version each instance runs before they can act.

---

## 3. Operational Pain

### 3.1 Backup Complexity

Per-application infrastructure distributes backup responsibility. Each team must implement backups for their infrastructure. Some teams do. Some teams do not. Some teams implement backups that do not actually work. There is no central verification that backups exist, function, or meet recovery requirements.

Backup complexity multiplies with instance count. Ten databases require ten backup configurations. Each configuration must be maintained, monitored, and tested. The operational burden scales linearly with the number of instances.

### 3.2 Upgrade Burden

Per-application infrastructure distributes upgrade burden. When a security vulnerability requires patching, every instance must be patched individually. There is no mechanism to patch all instances simultaneously. There is no assurance that all instances have been patched.

Upgrade coordination becomes impossible at scale. Coordinating upgrades across ten databases owned by ten teams requires ten separate scheduling conversations. Teams have different maintenance windows. Teams have different risk tolerances. The upgrade that takes hours for one database takes months across the platform.

### 3.3 Outage Blast Radius

Per-application infrastructure localizes some outages but distributes others. An outage in Team A's database affects only Team A. An outage in shared network infrastructure affects everyone. But the investigation is complicated because responders must determine which per-application infrastructure instances are affected and how.

Outage investigation requires infrastructure inventory. When an outage occurs, responders must know what exists to determine what is affected. Per-application infrastructure produces no reliable inventory. Investigation begins with discovery.

### 3.4 Monitoring Gaps

Per-application infrastructure produces monitoring gaps. Teams implement monitoring for their infrastructure. The monitoring varies in coverage, alerting thresholds, and response procedures. Some infrastructure has comprehensive monitoring. Some infrastructure has no monitoring.

Monitoring gaps mask failures. Infrastructure that is not monitored fails silently. The failure is discovered when a dependent application fails, not when the infrastructure fails. By then, the impact has propagated.

### 3.5 Capacity Planning Impossibility

Per-application infrastructure makes capacity planning impossible. There is no visibility into aggregate resource consumption. There is no way to predict growth. There is no mechanism to identify inefficiencies or consolidation opportunities.

Capacity surprises are guaranteed. Without visibility, resource exhaustion is discovered when it occurs, not predicted in advance. Remediation is reactive and urgent rather than proactive and planned.

---

## 4. Cost Risks

### 4.1 Resource Duplication

Per-application infrastructure duplicates resources. Each database instance consumes compute, storage, and network resources. Resources that could be shared are instead duplicated across instances. The duplication is invisible because there is no aggregate view.

Duplication costs compound. The cost of one unnecessary database instance is small. The cost of one hundred unnecessary database instances is significant. Duplication accumulates without visibility until cost reviews reveal the aggregate impact.

### 4.2 Operational Overhead

Per-application infrastructure multiplies operational overhead. Each instance requires maintenance. Each instance requires monitoring. Each instance requires backup verification. The operational cost per instance may be small; the aggregate operational cost is large.

Operational overhead is often invisible. Teams absorb the overhead as part of normal work. The overhead is not measured. The opportunity cost—what teams could accomplish if not maintaining infrastructure—is not quantified.

### 4.3 Expertise Dilution

Per-application infrastructure dilutes expertise. When every team operates its own database, no team develops deep database expertise. Each team knows enough to deploy and maintain their instance. No team knows enough to optimize, troubleshoot complex issues, or advise on best practices.

Expertise dilution produces suboptimal outcomes. Without deep expertise, teams make reasonable but non-optimal decisions. The aggregate of non-optimal decisions across many teams produces a platform that functions but does not perform.

### 4.4 License Fragmentation

Per-application infrastructure fragments licensing. Each team procures what it needs. There is no aggregate view of licensing. There is no leverage for enterprise agreements. There is no visibility into compliance.

License fragmentation increases costs and risk. Costs increase because volume discounts are not captured. Risk increases because compliance cannot be verified.

---

## 5. Reliability Risks

### 5.1 Untested Recovery

Per-application infrastructure produces untested recovery procedures. Teams may define recovery procedures. Teams rarely test them. When recovery is needed, the procedures may not work. The first test of the recovery procedure is the actual disaster.

Untested recovery is unreliable recovery. Recovery procedures that have not been executed successfully cannot be trusted to succeed when needed. Per-application infrastructure makes systematic recovery testing impractical.

### 5.2 Inconsistent Availability

Per-application infrastructure produces inconsistent availability characteristics. Some instances are configured for high availability. Some are not. There is no platform-wide availability guarantee because availability is determined per-instance.

Inconsistent availability produces unpredictable system behavior. Application A depends on highly available infrastructure. Application B depends on single-instance infrastructure. A platform-wide availability statement is impossible because the weakest link determines system availability.

### 5.3 Cascading Failures

Per-application infrastructure complicates cascade analysis. When infrastructure fails, dependent applications fail. Determining which applications depend on which infrastructure requires mapping that may not exist. Cascade paths are discovered during incidents, not documented in advance.

Cascading failures propagate unpredictably. Without dependency mapping, failures propagate along paths that are not understood until they manifest. Containment is reactive because the blast radius is not known in advance.

### 5.4 Resource Contention

Per-application infrastructure shares underlying platform resources without coordination. Multiple database instances on the same nodes contend for CPU. Multiple storage consumers contend for IOPS. The contention is unmanaged because each instance is managed independently.

Resource contention produces intermittent failures. Failures that occur only under contention are difficult to diagnose. The failure appears in one instance; the cause is in another instance on the same infrastructure. Correlation requires visibility that per-application infrastructure does not provide.

---

## 6. Correctness Risks

### 6.1 Schema Inconsistency

Per-application infrastructure produces schema inconsistencies. When multiple applications use similar data structures, each maintains its own schema. Schemas drift independently. Data that represents the same concept is structured differently across databases.

Schema inconsistency breaks data integration. Joining data across databases requires understanding each schema's peculiarities. Integration becomes a translation exercise rather than a simple query.

### 6.2 Data Isolation Failures

Per-application infrastructure risks data isolation failures. When teams configure their own infrastructure, isolation depends on each team's configuration correctness. Misconfiguration may expose data inappropriately. There is no central verification that isolation is correctly implemented.

Data isolation failures are security incidents. A single misconfiguration can expose sensitive data. Per-application infrastructure multiplies the misconfiguration surface area.

### 6.3 Consistency Model Confusion

Per-application infrastructure produces consistency model confusion. Different infrastructure instances may provide different consistency guarantees. Applications may assume guarantees that their infrastructure does not provide. The mismatch produces subtle correctness bugs.

Consistency bugs are difficult to diagnose. They manifest intermittently under specific conditions. They produce wrong results without error signals. Per-application infrastructure increases the likelihood of consistency mismatches.

---

## 7. Why Decentralization Breaks Determinism

### 7.1 Dependency Graph Incompleteness

Per-application infrastructure produces incomplete dependency graphs. The orchestration system requires explicit declaration of dependencies. When infrastructure is deployed per-application, the infrastructure dependencies are embedded within applications rather than visible to the orchestrator.

Dependency graph incompleteness breaks orchestration guarantees. The orchestrator cannot enforce ordering for dependencies it does not know about. Per-application infrastructure hides dependencies from the orchestrator.

### 7.2 Capability Model Violation

Per-application infrastructure violates the capability model. Capabilities must target named resources explicitly. Per-application infrastructure creates unnamed resources—infrastructure that exists but is not registered as a capability provider.

Capability model violation breaks dependency satisfaction. If a database is deployed within an application and not registered as a capability provider, no consumer can declare a dependency on it. The dependency exists but is not modeled.

### 7.3 Lifecycle Coupling

Per-application infrastructure couples infrastructure lifecycle to application lifecycle. When an application is deleted, its infrastructure may be deleted. When an application is upgraded, its infrastructure may be disrupted. The infrastructure lifecycle is not managed; it is incidental.

Lifecycle coupling breaks shared consumption. If multiple applications need the same infrastructure capability, they cannot share per-application infrastructure because the infrastructure lifecycle is tied to a single application.

### 7.4 State Non-Determinism

Per-application infrastructure introduces state non-determinism. The same deployment may succeed or fail depending on whether infrastructure happens to exist. The infrastructure's existence is not part of the orchestration model; it is a side effect of previous deployments.

State non-determinism violates orchestration invariants. The orchestration system requires that the same deployment specification produces the same outcome. Per-application infrastructure makes outcomes dependent on prior state that the orchestrator does not track.

### 7.5 Recovery Ambiguity

Per-application infrastructure produces recovery ambiguity. When recovery is needed, the orchestrator must know what to recover. Per-application infrastructure is not visible to the orchestrator. The orchestrator cannot determine what infrastructure exists, what state it is in, or how to restore it.

Recovery ambiguity breaks failure semantics. The orchestration system defines deterministic recovery. Per-application infrastructure places infrastructure outside the recovery model.

---

## 8. The Fundamental Problem

### 8.1 Infrastructure as Unmanaged State

Per-application infrastructure treats infrastructure as unmanaged state. It exists. It may or may not be documented. It may or may not be consistent. It may or may not meet requirements. There is no system of record. There is no enforcement mechanism.

Unmanaged state accumulates entropy. Without active management, systems drift toward disorder. Configurations diverge. Documentation decays. Knowledge dissipates. The platform becomes progressively less understandable.

### 8.2 Entropy as the Core Issue

Entropy—the tendency toward disorder—is the core issue. Per-application infrastructure maximizes entropy. Each deployment adds state. Each modification increases divergence. Each departure removes knowledge.

Entropy cannot be reversed by effort alone. Periodic cleanup campaigns address symptoms, not causes. The structure that permits entropy will recreate it. Only structural change—moving infrastructure ownership to a central platform function—addresses the root cause.

### 8.3 Centralization as Entropy Reduction

Shared infrastructure reduces entropy by design. A single instance replaces many. A single configuration replaces divergent configurations. A single team's expertise replaces diluted expertise. A single set of procedures replaces inconsistent procedures.

Entropy reduction is not optional. The consequences of entropy—operational pain, cost, reliability risks, correctness risks—are not acceptable. Entropy must be reduced. Shared infrastructure is the mechanism for reduction.

---

## 9. Summary

### 9.1 The Case for Shared Infrastructure

Shared infrastructure must exist because:

- Per-application infrastructure proliferates without governance
- Per-application infrastructure distributes operational burden unsustainably
- Per-application infrastructure duplicates costs invisibly
- Per-application infrastructure produces inconsistent reliability
- Per-application infrastructure introduces correctness risks
- Per-application infrastructure breaks orchestration determinism

### 9.2 The Structural Requirement

The problems documented in this RFC are not addressable by policy, training, or best practices. They are structural problems requiring structural solutions. The structure that permits per-application infrastructure must be replaced by a structure that mandates shared infrastructure.

The subsequent documents in RFC-P2 define when infrastructure must be shared, what guarantees shared infrastructure must provide, how shared infrastructure exposes capabilities, who owns shared infrastructure, and what patterns are forbidden.

---

*End of RFC-P2-01*
