# RFC-P1-04 — Capability Model

**Status:** Draft
**Audience:** Platform Engineers, Architects, Operations Teams

---

## 1. Introduction

This document defines the capability abstraction that forms the foundation of the orchestration system. It establishes what a capability is, how capabilities relate providers to consumers, and why capabilities must target explicit resources. This model replaces direct application-to-application dependencies with a semantic layer that captures what systems actually need from each other.

---

## 2. Capability Definition

### 2.1 What a Capability Is

A capability is a named, semantic unit of functionality that one resource provides and other resources may consume. A capability represents something meaningful to the platform: the ability to store data, the ability to issue certificates, the ability to route traffic, the ability to authenticate requests.

A capability is not a resource. A PostgreSQL database is a resource. The ability to store relational data with ACID guarantees is a capability. The distinction matters: resources are implementation, capabilities are interface.

A capability is not a service. A service is an addressable endpoint. A capability may be provided by a service, but the capability is what the service provides, not the service itself. A consumer does not depend on the existence of a service; it depends on the availability of what the service offers.

A capability is not a health state. A resource may be healthy without providing its capabilities. A database pod may be running without its schema being initialized. Health is survival; capability is function.

### 2.2 Capability Identity

Each capability must have a unique name within the system. The name must be meaningful and stable. The name identifies what is being provided, not who provides it or how.

Capability names must be chosen to reflect semantic function. A capability named "postgresql-ready" is poorly named because it identifies the provider. A capability named "relational-storage" is better named because it identifies what is provided.

Capability names must be unique. Two different capabilities must not share a name. If two resources provide the same capability name, they must be providing the same semantic function. If they are providing different functions, they must use different names.

### 2.3 Capability Granularity

Capabilities must be granular enough to express real dependencies. A capability that represents "database is running" is too coarse if consumers actually depend on specific schemas being present. A capability that represents "table X exists with column Y" is too fine if that level of detail is not meaningful to consumers.

The correct granularity is the granularity of consumer requirements. Consumers do not require arbitrary facts about providers. Consumers require specific functions. Capabilities must be defined at the granularity that captures these requirements.

A single resource may provide multiple capabilities. A database may provide "schema-initialized", "replication-configured", and "backup-enabled" as distinct capabilities. Different consumers may require different subsets of these capabilities.

---

## 3. Providers and Consumers

### 3.1 The Provider Role

A provider is a resource that satisfies a capability. When a provider has completed its initialization and is ready to serve its function, it provides its declared capabilities.

Providing a capability is an active declaration. The provider does not provide a capability merely by existing. The provider does not provide a capability merely by being healthy. The provider provides a capability when it has achieved the state necessary to satisfy that capability.

A provider must know what capabilities it provides. This knowledge must be explicit in the provider's definition. The orchestrator must not infer capabilities from provider behavior or structure.

A provider must signal when it has provided its capabilities. This signal must be explicit. The orchestrator must not assume capabilities are provided based on sync status, health status, or elapsed time.

### 3.2 The Consumer Role

A consumer is a resource that requires one or more capabilities before it can meaningfully operate. A consumer depends on capabilities, not on providers directly.

Consuming a capability is a declaration of requirement. The consumer declares that it requires certain capabilities. The consumer does not need to know which resources provide those capabilities. The consumer needs only the capabilities themselves.

A consumer must know what capabilities it requires. This knowledge must be explicit in the consumer's definition. The orchestrator must not infer requirements from consumer behavior or structure.

A consumer must not proceed until its required capabilities are provided. The orchestrator enforces this constraint. If a required capability is not yet provided, the consumer must wait.

### 3.3 The Provider-Consumer Relationship

The relationship between provider and consumer is mediated by capability. The provider provides capability X. The consumer requires capability X. The orchestrator connects them through X.

This mediation has important properties:

**Indirection:** The consumer does not reference the provider. The consumer references the capability. If the provider changes (different name, different implementation), the consumer is unaffected as long as the capability is still provided.

**Explicit Coupling:** The coupling between provider and consumer is visible in their declarations. The provider declares what it provides. The consumer declares what it requires. The orchestrator matches them. There is no hidden coupling.

**Semantic Coupling:** The coupling is based on meaning, not identity. The consumer needs relational storage. The provider offers relational storage. The coupling is at the semantic level, not the resource level.

### 3.4 Many-to-Many Relationships

The capability model supports many-to-many relationships:

**One Provider, Many Consumers:** A single database may provide a capability that multiple applications consume. Each application declares its requirement for the capability. The database provides it once. All consumers are satisfied.

**Many Capabilities, One Consumer:** A single application may require multiple capabilities from multiple providers. The application declares all its requirements. It proceeds only when all requirements are satisfied.

**One Provider, Many Capabilities:** A single resource may provide multiple capabilities. Each capability is independent. A consumer that requires only one of them needs only wait for that one.

---

## 4. Explicit Resource Targeting

### 4.1 Capabilities Target Named Resources

Capabilities do not float abstractly in the system. Each capability is provided by a specific, named resource. The capability declaration must identify this resource explicitly.

When a provider declares that it provides a capability, the declaration must include the identity of the providing resource. The orchestrator must know not just that capability X exists, but that resource A provides capability X.

When a consumer declares that it requires a capability, the orchestrator must be able to resolve which resource provides that capability. This resolution happens at orchestration time, not at runtime.

### 4.2 Why Explicit Targeting Is Required

Explicit targeting ensures that the dependency graph is concrete. Abstract capabilities without concrete providers would create ambiguity. The orchestrator must know exactly what depends on what.

Explicit targeting enables failure attribution. When a capability is not provided, the orchestrator knows which resource failed to provide it. Without explicit targeting, failure attribution would be impossible.

Explicit targeting prevents phantom dependencies. A capability that exists without a provider is an error. Explicit targeting ensures that every capability has a known provider and every requirement has a known source.

### 4.3 Resource Identity

Resources must have stable identities. The identity of a resource must not change across deployments. If resource A provides capability X in one deployment, and the "same" deployment runs again, resource A must still provide capability X.

Resource identity is typically the resource's name within the orchestration system. For ArgoCD Applications, this is the Application name. The name must be unique, stable, and meaningful.

The orchestrator uses resource identity to:
- Track which resources have been deployed
- Track which capabilities have been provided
- Track which requirements have been satisfied
- Attribute failures to specific resources

### 4.4 No Anonymous Capabilities

Every capability must be traceable to its provider. There must be no capability in the system that cannot be attributed to a specific, named resource.

Anonymous capabilities are prohibited because they cannot be debugged. If a capability is missing, the operator must be able to determine which resource failed to provide it. Anonymous capabilities make this determination impossible.

Anonymous capabilities are prohibited because they cannot be monitored. The orchestrator must be able to report which resources have provided their capabilities and which have not. Anonymous capabilities cannot be included in such reports.

---

## 5. Why Applications Do Not Depend on Applications

### 5.1 The Application Dependency Anti-Pattern

A common but incorrect model expresses dependencies directly between applications. Application B depends on Application A. When A is synced, B may sync.

This model is incorrect because it conflates identity with capability. B does not depend on A. B depends on what A provides. If A is synced but has not initialized its database schema, B's dependency is not satisfied. The application-to-application model cannot express this distinction.

### 5.2 Sync Status Is Not Dependency Satisfaction

ArgoCD reports that an Application is "Synced" when the resources in Git have been applied to the cluster. Synced means the manifests have been submitted. Synced does not mean the resources are functional.

If B depends on A at the application level, and the orchestrator releases B when A is synced, B may start before A is actually ready. The application dependency was satisfied (A is synced) but the real dependency was not satisfied (A is not functional).

This is the fundamental flaw of application-to-application dependencies. They use sync status as a proxy for readiness. Sync status is not readiness.

### 5.3 Applications Are Containers, Not Dependencies

An Application is a container for Kubernetes resources. It is an organizational unit. It is a deployment boundary. It is not a semantic unit.

Dependencies are semantic. Application B needs a database. Application B needs a certificate authority. Application B needs a message queue. These are semantic requirements that happen to be provided by resources contained in applications.

Expressing dependencies at the application level loses semantic information. "B depends on A" does not say what B needs or what A provides. "B requires relational-storage, A provides relational-storage" captures the semantic relationship.

### 5.4 Capability Dependencies Replace Application Dependencies

In the capability model, applications do not depend on applications. Resources require capabilities. Other resources provide capabilities. The orchestrator matches requirements to providers.

Applications still exist as organizational units. Resources are still grouped into applications. But dependencies are not expressed at the application level. Dependencies are expressed at the capability level, and the orchestrator enforces them regardless of how resources are grouped.

This model correctly captures semantic dependencies. It distinguishes between organizational structure (applications) and functional relationships (capabilities). It enables the orchestrator to enforce real dependencies, not proxy dependencies.

### 5.5 Consequences for Application Design

Because dependencies are expressed through capabilities, application boundaries do not affect dependency semantics. Resources may be reorganized between applications without changing the dependency graph.

If a database resource moves from Application A to Application B, and that database provides capability X, the dependency graph is unchanged. Resources that require capability X still require it. The provider is still the database resource. Only the organizational container has changed.

This decoupling enables flexible application design. Applications may be structured for operational convenience without concern for dependency implications. The capability model separates organizational concerns from dependency concerns.

---

## 6. Capability Model Summary

### 6.1 Core Principles

The capability model rests on the following principles:

**Capabilities are semantic:** They represent meaningful functions, not resource identities or health states.

**Dependencies are on capabilities:** Consumers require capabilities, not providers. The indirection is essential.

**Targeting is explicit:** Every capability has an identified provider. Every requirement is resolvable.

**Applications are organizational:** Dependencies exist between resources through capabilities, not between applications directly.

### 6.2 What the Model Provides

The capability model provides a language for expressing what resources need from each other. This language is richer than "A before B" and more precise than "A provides database."

The capability model provides a mechanism for the orchestrator to enforce real dependencies. Because capabilities capture semantic requirements, the orchestrator can enforce semantic satisfaction, not just ordering.

The capability model provides clarity for operators. When a deployment is blocked, the operator knows which capability is missing and which resource was supposed to provide it. The model makes dependencies visible and debuggable.

---

*End of RFC-P1-04*
