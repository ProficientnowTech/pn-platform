```
RFC-IAM-0001                                                  Section 2
Category: Standards Track                              Requirements
```

# 2. Requirements

[← Previous: Introduction](./01-introduction.md) | [Index](./00-index.md#table-of-contents) | [Next: Architecture →](./03-architecture.md)

---

## 2.1 Problem Restatement

### 2.1.1 Scope Definition

This RFC addresses **human user authentication to web applications** and **application-level authorization** for platform developer tools. Specifically:

| In Scope | Description |
|----------|-------------|
| Web UI authentication | Users logging into platform applications (container registry, package registry, developer portal) via browser |
| Application authorization | What actions users can perform within these applications |
| OIDC/OAuth flows | Browser-based authentication protocols |
| API authorization | REST API access using bearer tokens from OIDC flows |

| Out of Scope | Addressed By |
|--------------|--------------|
| Machine identity | Future RFC (Workload Identity) |
| Workload identity | Future RFC (Workload Identity) |
| Service-to-service authentication | Future RFC (Workload Identity) |
| AI agent identity management | Future RFC (Workload Identity) |
| SSH/shell access | RFC-PAM (Privileged Access) |
| Database access | RFC-PAM (Privileged Access) |
| Kubernetes exec/attach | RFC-PAM (Privileged Access) |
| Network access controls | RFC-PAM (Privileged Access) |

### 2.1.2 Core Requirements

The platform requires an identity and access management architecture that:

1. Federates enterprise identity (Azure AD) with platform identity (Keycloak) for **human users accessing web applications**
2. Ensures that enterprise-level access denials cannot be circumvented by platform-level configurations
3. Provides centralized **web UI authentication** for all platform developer tools
4. Provides centralized **application authorization** governing what users can do within these tools
5. Integrates with GitOps workflows for declarative configuration management
6. Enables developer self-service within organizational permission boundaries

The architecture must establish generic patterns applicable to any platform tool with a web interface, including container registries, package registries, developer portals, and monitoring dashboards.

## 2.2 Design Goals

### 2.2.1 Single Authentication Experience

Users SHOULD authenticate once through a consistent flow that validates their identity against both Azure AD and Keycloak. The authentication experience SHOULD be uniform across all platform applications, reducing cognitive overhead and credential management burden.

### 2.2.2 Authorization Inheritance

Authorization decisions SHOULD follow a clear inheritance model where permissions granted at the enterprise level (Azure AD) represent the maximum permissions available at the platform level (Keycloak). Platform-level configurations MAY restrict permissions further but MUST NOT extend them beyond enterprise boundaries. This MUST be a limitation by design.

### 2.2.3 Operational Simplicity

The architecture SHOULD minimize operational complexity by:

- Reducing the number of systems requiring independent configuration
- Providing clear patterns for common integration scenarios
- Enabling automated synchronization of identity changes
- Supporting standard protocols (OIDC, SAML) for application integration

### 2.2.4 Auditability

All authentication events, authorization decisions, and secret access MUST be auditable. The architecture MUST provide:

- Centralized logging of identity events
- Traceable authorization decision chains
- Secret access audit trails
- Change history for permission configurations

### 2.2.5 GitOps Compatibility

Configuration that defines "what exists" (roles, clients, resource definitions) SHOULD be managed through GitOps. Configuration that defines "who has what" (user-role assignments, group memberships) SHOULD be managed through administrative interfaces with audit trails.

### 2.2.6 Developer Enablement

Developers SHOULD be able to perform self-service actions (creating projects, repositories, packages) without administrative intervention, subject to their organizational permissions. The developer portal SHOULD provide clear feedback when actions are denied due to insufficient permissions.

## 2.3 Non-Goals

### 2.3.1 Replacing Azure AD

This architecture does not seek to replace Azure AD as the enterprise identity provider. Azure AD remains the authoritative source for organizational identity, group membership, and enterprise-level policies. Keycloak serves as a platform-level identity broker, not an enterprise identity replacement.

### 2.3.2 Full Automation of Access Control

User-to-role assignments and fine-grained permission decisions require human judgment and organizational context that cannot be fully automated. The architecture explicitly preserves administrative control over access assignments through the Keycloak administrative interface.

### 2.3.3 Multi-Cloud Identity Federation

This architecture addresses federation between Azure AD and Keycloak specifically. Federation with other cloud identity providers (AWS IAM, GCP Identity) is out of scope and would require separate architectural consideration.

### 2.3.4 End-User Application Identity

This architecture addresses identity for platform tools used by developers and operators. End-user application identity (customer authentication) is a separate concern addressed by application-specific architectures.

### 2.3.5 Network-Level Access Control

While identity informs access decisions, network-level controls (firewalls, network policies, service mesh authorization) are separate concerns. This architecture addresses application-level identity and authorization, not network segmentation.

### 2.3.6 Machine and Workload Identity

This RFC explicitly excludes non-human identity concerns. The following are out of scope and anticipated to be addressed by a future RFC (tentatively RFC-WORKLOAD-IDENTITY):

| Excluded Concern | Description |
|------------------|-------------|
| **Machine identity** | Identity for physical or virtual machines authenticating to services |
| **Workload identity** | Identity for Kubernetes pods, containers, or serverless functions |
| **Service-to-service authentication** | How backend services authenticate to each other (mTLS, SPIFFE/SPIRE) |
| **AI agent identity** | Identity and authorization for autonomous AI agents or bots |
| **Service mesh identity** | Istio, Linkerd, or similar service mesh identity mechanisms |
| **CI/CD pipeline identity** | How build pipelines authenticate to deploy or access resources |

These concerns require different architectural patterns:

| This RFC (Human → Web App) | Workload Identity RFC |
|---------------------------|----------------------|
| Browser-based OIDC flows | Certificate-based mTLS |
| Human initiates authentication | Automated credential injection |
| Session-based authorization | Per-request authorization |
| Keycloak as IdP | SPIFFE/SPIRE or cloud workload identity |
| User clicks "Login" | Workload bootstraps identity automatically |

The distinction is fundamental: this RFC addresses **interactive human users accessing web interfaces**, not **automated workloads authenticating to APIs**.

### 2.3.7 Secret Lifecycle Management (Deferred to RFC-SECOPS-0001)

The comprehensive architecture for secret management—including bootstrap, rotation, authority transitions, and distribution mechanics—is defined in [RFC-SECOPS-0001](../secret-ops/00-index.md). This RFC references RFC-SECOPS-0001 for all secret-related concerns and does not duplicate or supersede that specification.

RFC-SECOPS-0001 governs **all secrets** where Vault serves as the central authority—not just machine secrets, but any secret that can be managed through the Vault-first architecture. RFC-SECOPS-0001 explicitly excludes "Cross-System IAM Design" from its scope (Section 2.3.4), which this RFC addresses. The two RFCs are complementary:

| Concern | Authoritative RFC |
|---------|-------------------|
| User identity and authentication | RFC-IAM-0001 (this document) |
| Application authorization | RFC-IAM-0001 (this document) |
| Secret storage and lifecycle | RFC-SECOPS-0001 |
| Secret rotation and distribution | RFC-SECOPS-0001 |
| Vault policy integration with identity | Both (integration point) |

### 2.3.8 Infrastructure and Privileged Access Management

The following infrastructure access concerns are explicitly out of scope and anticipated to be addressed by a future RFC (tentatively RFC-PAM):

- **SSH access to infrastructure**: How users obtain shell access to Kubernetes nodes, VMs, or on-premises servers
- **Database port access**: How developers connect to PostgreSQL, Redis, or other database services
- **VPC and network perimeter access**: External access to private networks, VPN configurations
- **Kubernetes exec/attach access**: Governing who can execute commands in pods or attach to containers
- **Command auditing**: Recording and auditing commands executed on infrastructure

While these concerns share common tools with this architecture (Keycloak for identity, Vault for credentials), they represent a distinct domain:

| This RFC (IAM) | Future Infrastructure Access RFC |
|----------------|----------------------------------|
| Application-level authorization | Infrastructure-level access |
| OIDC tokens for web applications | SSH certificates, database credentials |
| Who can use platform applications | Who can SSH to nodes, connect to databases |
| Keycloak roles → Application permissions | Keycloak identity → Infrastructure access |

The future RFC would define how identity (established by this RFC) translates into infrastructure access rights, potentially using:
- Vault SSH secrets engine for certificate-based SSH
- Vault database secrets engine for dynamic database credentials
- Boundary or similar tools for session recording and access brokering
- Network policies governed by identity attributes

### 2.3.9 Tenant Application Security

Security controls for tenant-deployed applications are explicitly out of scope and anticipated to be addressed by a future RFC (tentatively RFC-TENANT-SECURITY):

- **Web Application Firewall (WAF)**: Rules and policies protecting tenant web applications
- **Network policies**: Kubernetes NetworkPolicy, Calico, Cilium policies for tenant namespaces
- **Ingress/egress security**: Traffic control at namespace and cluster boundaries
- **API gateway security**: Rate limiting, authentication policies at the gateway level
- **Routing policies**: Traffic management and security for tenant applications
- **DDoS protection**: Protecting tenant applications from denial of service

This domain addresses: "How do we protect applications that business units deploy on our platform?"

| This RFC (IAM) | RFC-TENANT-SECURITY |
|----------------|---------------------|
| Human authentication to web UIs | Application perimeter defense |
| Authorization within applications | Network-level traffic control |
| Who can use platform tools | How tenant apps are protected |
| Keycloak/OIDC flows | WAF rules, network policies |

RFC-TENANT-SECURITY may reference RFC-WORKLOAD-IDENTITY for identity-based network policies (e.g., "only workloads with identity X can reach service Y").

## 2.4 Architectural Invariants

The following invariants MUST hold true at all times. Violation of any invariant represents a security failure requiring immediate remediation.

### Invariant 1 — Authorization Ceiling (Conjunctive Authorization)

Azure AD and Keycloak operate as a conjunctive (AND) authorization gate. Access to any resource requires agreement from both systems according to the following truth table:

| Azure AD | Keycloak | Result |
|----------|----------|--------|
| Allow | Allow | **Allow** |
| Allow | Deny | **Deny** |
| Deny | Allow | **Deny** |
| Deny | Deny | **Deny** |
| Undefined | Allow | **Allow** |
| Undefined | Deny | **Deny** |

Where:
- **Allow**: The system explicitly grants access through group membership (Azure AD) or role assignment (Keycloak)
- **Deny**: The system explicitly or implicitly denies access (absence of required group/role)
- **Undefined**: Azure AD has no policy regarding the resource (platform-specific resources not governed by enterprise policy)

Keycloak MUST NOT grant access to any resource that Azure AD denies to the requesting principal. If a user's Azure AD group membership does not include access to resource R, Keycloak MUST NOT grant access to resource R regardless of Keycloak role assignments, client configurations, or policy definitions.

Conversely, Azure AD allowing access does not automatically grant access—Keycloak MUST also permit the action through appropriate role assignments. The systems function as two independent gates that MUST both be open for access to proceed.

This conjunctive model ensures:
- Enterprise security policy cannot be bypassed through platform-level configuration
- Platform administrators can further restrict access below the enterprise ceiling
- Neither system alone can grant access; both must agree
- Denial by either system results in denial regardless of the other system's decision

### Invariant 2 — Authentication Chain

All platform application authentication MUST flow through Keycloak, and Keycloak MUST validate the user's identity against Azure AD before issuing tokens.

No platform application MAY authenticate users through mechanisms that bypass the Keycloak-Azure AD authentication chain.

This invariant ensures consistent identity validation and audit logging.

### Invariant 3 — Secret Authority (Reference: RFC-SECOPS-0001)

HashiCorp Vault MUST be the sole authoritative source for secrets required by platform applications. This invariant is defined and governed by [RFC-SECOPS-0001](../secret-ops/00-index.md), which establishes the comprehensive secret management architecture.

Per RFC-SECOPS-0001 Invariant 5: "Kubernetes Is a Consumer, Not an Authority"—Kubernetes Secrets exist only to satisfy application consumption requirements. They are derived artifacts, not sources of truth.

This RFC defers to RFC-SECOPS-0001 for:
- Secret lifecycle management (bootstrap, runtime, rotation)
- Authority transitions and phase model
- Cross-namespace secret distribution (PushSecret/ExternalSecret patterns)
- Rotation framework and automation requirements

The relationship between identity (this RFC) and secrets (RFC-SECOPS-0001):
- Identity determines **who** can access secrets (Vault policies derive from Keycloak identities)
- RFC-SECOPS-0001 determines **how** secrets are managed, stored, and distributed
- Both systems operate independently but integrate at the Vault policy layer

### Invariant 4 — Secret Distribution Control (Reference: RFC-SECOPS-0001)

Secrets MUST be distributed to application namespaces through the mechanisms defined in [RFC-SECOPS-0001 Section 5a](../secret-ops/05a-internal-distribution.md).

Per RFC-SECOPS-0001 Invariant 7: Internal secrets requiring cross-namespace distribution MUST traverse Vault via PushSecret/ExternalSecret patterns. Direct namespace-to-namespace secret copying is forbidden.

This RFC does not redefine secret distribution mechanics—RFC-SECOPS-0001 is authoritative for all secret distribution concerns.

### Invariant 5 — GitOps Resource Authority

All identity-dependent resources (Keycloak clients, Crossplane managed resources, application configurations) MUST be defined in Git and deployed through the GitOps pipeline.

Manual creation of these resources through CLI tools, APIs, or administrative interfaces MUST NOT occur in production environments.

This invariant ensures configuration version control and peer review.

### Invariant 6 — Administrative Boundary

User-to-role assignments and group-to-role mappings in Keycloak MUST be managed through the Keycloak administrative interface, not through GitOps.

This invariant preserves human oversight over access grants while maintaining declarative configuration for structural elements.

### Invariant 7 — Synchronization Consistency

Azure AD group memberships MUST be synchronized to Keycloak within the defined synchronization interval.

Keycloak MUST NOT cache stale group membership data beyond the synchronization interval.

This invariant ensures that enterprise permission changes propagate to the platform.

### Invariant 8 — Crossplane Template Coupling

Crossplane provider resources that create application-specific entities (registry projects, package scopes, etc.) MUST be templated through the same Helm chart values that deploy the parent application.

Resource definitions MUST NOT exist independently of their associated application deployment.

This invariant ensures that resource lifecycle is coupled with application lifecycle.

### Invariant 9 — Developer Portal Integration (Reference: RFC-DEVELOPER-PLATFORM)

The developer portal (Backstage) architecture is defined in [RFC-DEVELOPER-PLATFORM-0001](../developer-platform/00-index.md).

This RFC establishes only the identity integration point:
- The developer portal MUST authenticate users through Keycloak (per Invariant 2)
- Keycloak tokens provide the permission claims the developer portal uses

RFC-DEVELOPER-PLATFORM will define:
- **Capability-based UI**: Users see only actions they are permitted to perform
- **Permission-aware rendering**: UI components adapt based on Keycloak claims
- **Elimination of runtime authorization checks**: By not presenting unauthorized options, authorization enforcement shifts from "block when attempted" to "never show"

This model ensures:
- Users cannot attempt actions they lack permission for (no UI path exists)
- Simpler user experience (no permission denied errors)
- Authorization is enforced at the UI layer through visibility, not at the action layer through blocking

### Invariant 10 — Token Validation

All platform applications MUST validate tokens issued by Keycloak before granting access.

Applications MUST NOT trust tokens without cryptographic verification against Keycloak's public keys.

This invariant prevents token forgery and ensures all access flows through the authentication chain.

## 2.5 Success Criteria

The architecture succeeds when the following conditions are met:

### 2.5.1 Security Criteria

| Criterion | Validation |
|-----------|------------|
| No permission escalation pathways exist | Security review confirms Azure AD denial cannot be bypassed |
| All authentication flows through Keycloak | Network inspection confirms no direct application authentication |
| All secrets originate from Vault | Audit confirms no secrets outside ESO management |
| Terminated users lose access promptly | Access revocation occurs within synchronization interval |

### 2.5.2 Operational Criteria

| Criterion | Validation |
|-----------|------------|
| Single sign-on across all platform tools | Users authenticate once per session |
| GitOps deployment of identity configuration | All structural configuration in Git |
| Automated secret distribution | ESO successfully synchronizes secrets |
| Developer self-service functional | See RFC-DEVELOPER-PLATFORM for validation criteria |

### 2.5.3 Integration Criteria

| Criterion | Validation |
|-----------|------------|
| Platform applications authenticate through Keycloak | OIDC integration functional for all integrated apps |
| Developer portal authenticates through Keycloak | See RFC-DEVELOPER-PLATFORM for authorization model |
| Crossplane resources deploy through GitOps | Resources reconcile from Git definitions |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 1. Introduction](./01-introduction.md) | [Table of Contents](./00-index.md#table-of-contents) | [3. Architecture →](./03-architecture.md) |

---

*End of Section 2 — RFC-IAM-0001*
