```
RFC-PLATARCH-0001                                            Appendix A
Category: Standards Track                                       Glossary
```

# Appendix A: Glossary

[← Evolution](./10-evolution.md) | [Index](./00-index.md#table-of-contents) | [Next: References →](./appendix-b-references.md)

---

## A.1 Terms and Definitions

This glossary defines terms used throughout RFC-PLATARCH-0001. Terms are listed alphabetically.

---

### A

**Application**
A workload deployed on the platform through the base chart. Platform applications consume capabilities and may provide capabilities.

**Application-Owned Resource**
A Kubernetes resource owned by an application team. Application-owned resources exist within application namespaces and follow application lifecycle.

**AppProject**
An ArgoCD construct that defines permission boundaries for applications. AppProjects restrict what repositories, clusters, namespaces, and resource types an ArgoCD Application can access.

**ArgoCD**
The GitOps continuous delivery tool used by the platform for reconciling cluster state with Git-defined state. ArgoCD is the deployment engine; the orchestrator determines deployment timing.

---

### B

**Base Chart**
The single, canonical Helm chart that all platform applications must use for integration. The base chart provides capability declaration, secret integration, identity wiring, and platform compliance.

**Blast Radius**
The scope of impact from a failure or security incident. Platform governance aims to contain blast radius through isolation and permission boundaries.

**Breaking Change**
A change that causes existing, correct consumers to fail or behave incorrectly. Breaking changes require RFC process, deprecation period, and migration support.

---

### C

**Capability**
A discrete, well-defined function that a platform component provides or requires. Capabilities are the unit of dependency in the orchestration model.

**Capability Contract**
The formal agreement between a capability provider and its consumers. Contracts specify interface, guarantees, constraints, and versioning.

**Capability Satisfaction**
The state where a required capability is provided by a ready provider with a compatible contract version. Deployment proceeds when all required capabilities are satisfied.

**Consumer**
A component that requires a capability. Consumers declare requirements and wait for satisfaction before deployment.

**CRD (Custom Resource Definition)**
A Kubernetes API extension that defines a new resource type. CRDs are platform-owned and may not be created by applications.

**CR (Custom Resource)**
An instance of a Custom Resource Definition. CR ownership depends on purpose: platform CRs are platform-owned; application CRs may be application-owned.

---

### D

**Declarative**
A configuration approach where desired state is declared rather than procedurally constructed. The platform prefers declarative specifications.

**Decommissioning**
The process of removing infrastructure or applications from the platform. Decommissioning follows defined rules including consumer verification, deprecation, and data handling.

**Dependency**
A requirement relationship between components. In the capability model, dependencies are expressed as capability requirements, not component references.

**Deprecation**
The process of marking a feature or capability for future removal. Deprecation includes notice, deprecation period, migration guidance, and eventual removal.

**Deterministic**
A property where same inputs produce same outputs. Orchestration must be deterministic—the same capability graph produces the same deployment sequence.

**Drift**
A state where actual cluster state differs from declared Git state. Drift is incorrect state that must be corrected. Drift applies only to ArgoCD-managed resources.

---

### E

**Ephemeral Resource**
A resource intended to be short-lived, such as individual Pods or completed Jobs. Ephemeral resources are not managed through GitOps.

**Explicit**
A design principle where dependencies, configurations, and behaviors are stated directly rather than inferred. The platform requires explicit capability declarations.

---

### G

**GitOps**
An operational model where Git is the source of truth for infrastructure and application configuration. Changes are made through Git commits and automatically reconciled to the cluster.

**Governance**
The rules and processes that ensure platform integrity. Governance includes ownership rules, change management, permission boundaries, and compliance enforcement.

**Guarantee**
A commitment made by a capability provider to consumers. Guarantees include availability, durability, and stability commitments documented in capability contracts.

---

### I

**Idempotent**
A property where an operation produces the same result regardless of how many times it is performed. All platform state-changing operations must be idempotent.

**Identity**
The credential set assigned to an application by the platform. Platform identity is used for authentication, authorization, and audit attribution.

**Infrastructure**
Services that provide foundational capabilities such as databases, message queues, and identity systems. Shared infrastructure is platform-owned.

**Invariant**
A property that must always hold. Platform invariants include capability satisfaction before deployment, single ownership, and explicit declaration.

---

### L

**Lifecycle**
The stages a component passes through from creation to removal. Lifecycle includes provisioning, operation, maintenance, deprecation, and decommissioning.

---

### M

**Monotonic**
A property where state progression is forward-only. Capability guarantees are monotonic—they may be maintained or improved but not degraded within a major version.

---

### N

**Namespace**
A Kubernetes construct that provides isolation boundaries. Namespaces are governance units with single ownership, isolation requirements, and lifecycle alignment.

**Namespace Isolation**
The property where resources in different namespaces cannot access each other without explicit authorization. Isolation includes network, access control, and resource boundaries.

---

### O

**Operator**
A Kubernetes controller that manages specific resource types. Operators are platform-owned and may not be installed by applications.

**Orchestration**
The process of sequencing deployments based on capability satisfaction. The orchestrator determines when applications are deployed; ArgoCD performs the deployment.

**Orchestrator**
The platform component responsible for sequencing deployments. The orchestrator observes capability state and triggers deployments when requirements are satisfied.

**Ownership**
Responsibility and authority over a resource. Every resource has exactly one owner. Ownership determines who maintains, modifies, and decommissions a resource.

---

### P

**Platform**
The collection of infrastructure, services, and governance that enables application deployment. The platform provides capabilities; applications consume them.

**Platform Application**
An application that integrates with the platform through the base chart, declares capabilities, and follows platform governance. See "Application."

**Platform-Owned Resource**
A resource owned by the platform team. Platform-owned resources include cluster infrastructure, operators, CRDs, and shared infrastructure.

**Provider**
A component that satisfies a capability. Providers register capabilities and signal readiness. Each capability has exactly one provider per scope.

---

### R

**Readiness**
The state where a capability is functionally available. Semantic readiness goes beyond pod running state to verify that the capability can serve its purpose.

**Reconciliation**
The process of making actual state match desired state. ArgoCD performs reconciliation by applying Git-defined manifests to the cluster.

**Requirement**
A declaration that a component needs a specific capability. Requirements specify capability name, version constraint, and whether the requirement is mandatory.

**RFC (Request for Comments)**
A formal document proposing or defining platform architecture, changes, or governance. RFCs follow defined process including review, approval, and lifecycle management.

**Runtime State**
State generated at runtime by controllers, operators, or applications. Runtime state is not managed through GitOps and is protected from reconciliation.

---

### S

**Secret**
Sensitive material requiring protection, such as credentials, certificates, or keys. Secrets must be declared by applications and provisioned by the platform.

**Semantic Versioning**
A versioning scheme (MAJOR.MINOR.PATCH) that communicates compatibility. Major version changes indicate breaking changes; minor and patch changes are backward compatible.

**Shared Infrastructure**
Infrastructure that serves multiple applications through a common deployment. Shared infrastructure is platform-owned with capability contracts.

**Single Source of Truth**
A principle where each piece of information has exactly one authoritative source. Git is the single source of truth for platform configuration.

**Stability Level**
A classification indicating how mature a capability contract is. Levels are Stable (committed), Beta (maturing), and Alpha (experimental).

**Sync Wave**
An ArgoCD mechanism for ordering resources within an Application. Sync waves provide coarse ordering but are insufficient for cross-application orchestration.

---

### T

**Tenant**
An application or consumer using shared infrastructure. Tenants are isolated from each other within shared infrastructure.

**TLS (Transport Layer Security)**
The encryption protocol for secure communication. All exposed services must use TLS; there are no exceptions.

---

### W

**Whitelist**
An explicit list of permitted items. Resource restrictions use whitelists—only explicitly permitted resources are allowed; all others are denied.

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 10. Evolution](./10-evolution.md) | [Table of Contents](./00-index.md#table-of-contents) | [Appendix B: References →](./appendix-b-references.md) |

---

*End of Appendix A — RFC-PLATARCH-0001*
